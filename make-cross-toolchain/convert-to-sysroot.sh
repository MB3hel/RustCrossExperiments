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

# Get absolute path with no trailing slash
# Important for how links are fixed
destdir="$(realpath "$1")"
destdir="${destdir%"/"}"
if [ ! -d "$destdir" ]; then
    echo "Destination folder does not exist."
    exit 1
fi

# Copy files matching certain patterns
echo "Copying files to sysroot directory"
rsync -a \
    --exclude=bin \
    --exclude=sbin \
    --exclude=src \
    --exclude=share \
    --exclude=libexec \
    --exclude=games \
    --exclude=lib/aarch64-linux-gnu/dri \
    --exclude=lib/firmware \
    --exclude=local/cuda-10.2/doc \
    --exclude=local/cuda-10.2/samples \
    --exclude=lib/systemd \
    "/usr/" "$destdir/usr/"
rsync -a "/opt/" "$destdir/opt/"
echo ""

# Convert links to all be relative
# This ensures that symlinks work outside of chroot environment
# It also replaces hard links with symlinks
echo "Fixing links in sysroot"
while read lnew; do
    if [ -z "$lnew" ]; then
        # Empty string -> find probably found nothing?
        continue
    fi

    # Links is in $destdir
    # Eg /mnt/sysroot/usr/lib/aarch64-linux-gnu/file
    # Original link (pre-copy) was /usr/lib/aarch64-linux-gnu/file
    # So remove prefix $destdir
    # Note that destdir was realpath'd earlier so it is absolute and "clean"
    lorig="${lnew#"$destdir"}"

    # If original link is broken, skip
    if [ ! -L "$lorig" ] || [ ! -e "$lorig" ]; then
        # echo "Original Link Was Broken: $lorig"
        continue
    fi

    # Original (absolute) target
    tabs="$(realpath "$lorig")"
    
    # Then, get a relative path from the original link to it's target
    trel="$(realpath --relative-to="$(dirname "$(realpath -s "$lorig")")" "$tabs")"

    # This relative target becomes the target for the new link
    ln -sf "$trel" "$lnew"
done <<< "$(find "$destdir" -type l)"
echo ""

# Finally, check for any broken links
# This is mostly useful in determining if anything important was missed previously
# This doesn't fix broken links. Just prints them so user knows if script
# needs to be modified to fix them
echo "Checking for broken links"
while read lnew; do
    if [ ! -L "$lnew" ] || [ ! -e "$lnew" ]; then
        echo "Found broken link in sysroot: $lnew"
        lorig="${lnew#"$destdir"}"
        if [ ! -L "$lorig" ] || [ ! -e "$lorig" ]; then
            echo "Original link was broken."
        else
            tabs="$(realpath "$lorig")"
            echo "Originally linked to $tabs"
        fi
        echo ""
    fi
done <<< "$(find "$destdir" -type l)"
echo ""

# Done. No cleanup necessary.
echo "Sysroot created."
