#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root!"
    exit 1
fi

# Parse arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 dest_folder"
    echo "Makes a sysroot folder from a chrooted image. Run in chroot!"
    echo ""
    echo "Example:"
    echo "  $0 /mnt/sysroot"
    echo ""
    exit 1
fi
destdir="$1"
if [ ! -d "$destdir" ]; then
    echo "Destination folder does not exist."
    exit 1
fi

# # Copy files matching certain patterns
# rsync -a \
#     --exclude=bin \
#     --exclude=sbin \
#     --exclude=src \
#     --exclude=share \
#     --exclude=libexec \
#     --exclude=games \
#     --exclude=lib/aarch64-linux-gnu/dri \
#     --exclude=lib/firmware \
#     --exclude=local/cuda-10.2/doc \
#     --exclude=local/cuda-10.2/samples \
#     --exclude=lib/systemd \
#     "/usr/" "$destdir/usr/"
# rsync -a "/opt/" "$destdir/opt/"

# Copy symlinked libraries to the expected location
basefiles=()
while read f; do
    if [ -L "$f" ] && [ -f "$f" ]; then
        r=$(readlink -f "$f")
        # rm -f "$f"
        # cp "$r" "$f"
        fdir="$(dirname \"$f\")"
        rdir="$(dirname \"$r\")"
        fidr=${fdir#"$destdir"}
        rdir=${rdir#"$destdir"}
        if [ ! "$fdir" -ef "$rdir" ]; then
            echo "$fdir"
            echo "$rdir"
            echo ""
        fi 
        basefiles+=("$f")
    fi
done <<< "$(find "$destdir/usr/lib/aarch64-linux-gnu/" -name "*.so*")"

# Delete all the base files (symlinked into a higher up directory)
# These shouldn't be needed by anything since these files are now in /usr/lib/aarch64-linux-gnu/
# which should be searched first anyway, but who knows. It could break something
# But it drastically reduces sysroot size, so until something doesn't like it...
