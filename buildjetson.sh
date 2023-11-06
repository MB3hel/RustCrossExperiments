#!/usr/bin/env bash

# Used by wrapper script
export SYSROOT=$HOME/jetsonroot

# Select correct linker
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=aarch64-linux-gnu-ar

# Add rpath-link arguments to rustflags
# Note: rpath-link must come before sysroot
lib_search_paths=(
    # Standard search paths for sysroot 
    $SYSROOT/usr/lib/aarch64-linux-gnu/
    $SYSROOT/lib/aarch64-linux-gnu/
    $SYSROOT/usr/local/lib/aarch64-linux-gnu/
    $SYSROOT/usr/local/cuda-10.2/targets/aarch64-linux/lib/
    $SYSROOT/opt/opencv-4.6.0/lib/

    # Some subdirectories are needed b/c these are in /usr/lib/aarch64-linux-gnu/
    # by symlinks (absolute) which don't work in the sysroot!
    # May need to add to these if adding libraries that work this way
    # Essentially, if it uses debian's update-alternatives thing, it's symlinked
    # TODO: Determine if there's a way to rewrite to relative symlinks
    #       when creating sysroot
    $SYSROOT/usr/lib/aarch64-linux-gnu/tegra/
    $SYSROOT/usr/lib/aarch64-linux-gnu/lapack/
    $SYSROOT/usr/lib/aarch64-linux-gnu/blas/
)
rustflags=""
for path in "${lib_search_paths[@]}"; do
    rustflags="$rustflags -C link-args=-Wl,-rpath-link,$path"
done
rustflags="${rustflags:1}"

# Add Sysroot flag. MUST BE AFTER rpath-link SETTINGS!!!
rustflags="$rustflags -C link-args=-Wl,--sysroot=$SYSROOT"

export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="$rustflags"

# Ensures OpenCV builds with right compiler
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-gcc

# Ensures correct OpenCV found (using Cmake search method)
lib_array=($SYSROOT/opt/opencv-4.6.0/lib/*.so)
for i in "${!lib_array[@]}"; do
    lib_name=$(basename ${lib_array[$i]} .so)
    lib_name=${lib_name#"lib"}
    lib_array[$i]=$lib_name
done
export OPENCV_LINK_LIBS="$(IFS=,; echo "${lib_array[*]}")"
export OPENCV_LINK_PATHS="$SYSROOT/opt/opencv-4.6.0/lib/"
export OPENCV_INCLUDE_PATHS="$SYSROOT/opt/opencv-4.6.0/include/opencv4"

# Run the build
cargo build --target aarch64-unknown-linux-gnu