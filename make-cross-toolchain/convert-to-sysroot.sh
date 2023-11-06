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

# Convert links to all be relative
# This ensures that symlinks work outside of chroot environment
# It also replaces hard links with symlinks
# TODO: Untested
while read l; do
    tabs="$(realpath "$l")"
    trel="$(realpath --relative-to="$(dirname "$(realpath -s "$l")")" "$target")"
    echo "$l -> $trel"
    # ln -sf "$trel" "$l"
done <<< "$(find "$destdir" -type l)"
