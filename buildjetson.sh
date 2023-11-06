#!/usr/bin/env bash

################################################################################
# Default settings
################################################################################
# Default values if these are not specified via env vars
[ -z "$JETSON_SYSROOT" ] && JETSON_SYSROOT=$HOME/sysroot-jetson
[ -z "$JETSON_TOOLCHAIN" ] && JETSON_TOOLCHAIN=$HOME/toolchain-jetson/
[ -z "$JETSON_TOOLCHAIN_PREFIX" ] && JETSON_TOOLCHAIN_PREFIX=aarch64-linux-gnu-
################################################################################



################################################################################
# Environment setup
################################################################################
# Make sure toolchain binaries are found in path!
export PATH=$JETSON_TOOLCHAIN/bin:$PATH

# Make sure any C/C++ code built by crates uses right compilers
export CC=${JETSON_TOOLCHAIN_PREFIX}gcc
export CXX=${JETSON_TOOLCHAIN_PREFIX}g++
################################################################################



################################################################################
# Rust flags
################################################################################
# Search paths for libraries (IN SYSROOT!!!)
lib_search_paths=(
    # Standard search paths
    $JETSON_SYSROOT/usr/lib/aarch64-linux-gnu/
    $JETSON_SYSROOT/lib/aarch64-linux-gnu/
    $JETSON_SYSROOT/usr/local/lib/aarch64-linux-gnu/

    # CUDA libraries are here
    $JETSON_SYSROOT/usr/local/cuda-10.2/targets/aarch64-linux/lib/

    # Custom build of OpenCV is installed here
    $JETSON_SYSROOT/opt/opencv-4.6.0/lib/
)
rustflags=""
for path in "${lib_search_paths[@]}"; do
    rustflags="$rustflags -C link-args=-Wl,-rpath-link,$path"
done
rustflags="${rustflags:1}"

# Add Sysroot flag AFTER rpath-link flags
rustflags="$rustflags -C link-args=-Wl,--sysroot=$JETSON_SYSROOT"
################################################################################



################################################################################
# Cargo flags / tools setup for target
################################################################################
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=${JETSON_TOOLCHAIN_PREFIX}gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=${JETSON_TOOLCHAIN_PREFIX}ar
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="$rustflags"
################################################################################


################################################################################
# OpenCV stuff
################################################################################
# Ensures correct OpenCV found (using environment var search method)
lib_array=($JETSON_SYSROOT/opt/opencv-4.6.0/lib/*.so)
for i in "${!lib_array[@]}"; do
    lib_name=$(basename ${lib_array[$i]} .so)
    lib_name=${lib_name#"lib"}
    lib_array[$i]=$lib_name
done
export OPENCV_LINK_LIBS="$(IFS=,; echo "${lib_array[*]}")"
export OPENCV_LINK_PATHS="$JETSON_SYSROOT/opt/opencv-4.6.0/lib/"
export OPENCV_INCLUDE_PATHS="$JETSON_SYSROOT/opt/opencv-4.6.0/include/opencv4"
export OPENCV_DISABLE_PROBES="pkg_config,cmake,vcpkg_cmake,vcpkg"
################################################################################



################################################################################
# Run the build
################################################################################
rustup target add aarch64-unknown-linux-gnu
cargo build --target aarch64-unknown-linux-gnu --target-dir target-jetson
################################################################################
