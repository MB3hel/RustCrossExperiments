#!/usr/bin/env bash

# Used by wrapper script
export SYSROOT=$HOME/sysroot-jetson
export TOOLCHAIN_PATH=/home/marcus/x-tools/aarch64-jetsonnano-linux-gnu
export TOOLCHAIN_PREFIX=aarch64-jetsonnano-linux-gnu-

# Make sure toolchain is found in path!
export PATH=$TOOLCHAIN_PATH/bin:$PATH

# Select correct linker
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=${TOOLCHAIN_PREFIX}gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=${TOOLCHAIN_PREFIX}ar

# Add rpath-link arguments to rustflags
# Note: rpath-link must come before sysroot
lib_search_paths=(
    # Standard search paths for sysroot 
    $SYSROOT/usr/lib/aarch64-linux-gnu/
    $SYSROOT/lib/aarch64-linux-gnu/
    $SYSROOT/usr/local/lib/aarch64-linux-gnu/
    $SYSROOT/usr/local/cuda-10.2/targets/aarch64-linux/lib/

    # Custom build of OpenCV is installed here
    $SYSROOT/opt/opencv-4.6.0/lib/
)
rustflags=""
for path in "${lib_search_paths[@]}"; do
    rustflags="$rustflags -C link-args=-Wl,-rpath-link,$path"
done
rustflags="${rustflags:1}"

# Add Sysroot flag. MUST BE AFTER rpath-link SETTINGS!!!
# rustflags="$rustflags -C link-args=-Wl,--sysroot=$SYSROOT"

export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="$rustflags"

# Ensures OpenCV builds with right compiler
export CC=${TOOLCHAIN_PREFIX}gcc
export CXX=${TOOLCHAIN_PREFIX}g++

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