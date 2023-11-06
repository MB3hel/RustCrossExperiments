#!/usr/bin/env bash

# Used by wrapper script
export SYSROOT=$HOME/jetsonroot

# Select correct linker
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=$(pwd)/aarch64-linux-gnu-gcc-wrapper
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=aarch64-linux-gnu-ar

# Rustflags
# export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS=""

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