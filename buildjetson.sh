#!/usr/bin/env bash

################################################################################
# Setup
################################################################################
# Default value if not specified via env var
[ -z "$JETSON_SYSROOT" ] && JETSON_SYSROOT=$HOME/sysroot-jetson
################################################################################


################################################################################
# Flags passed to clang
################################################################################
# Passed to everything (clang, clang++, linker, rustflags as link-args)
SHARED_FLAGS_ARR=(
    # Tells clang to compile for aarch64 linux
    -target
    aarch64-linux-gnu

    # Jetson Nano CPU
    -mcpu=cortex-a57

    # Tells clang to link with lld, which also supports -target aarch64-linux-gnu
    -fuse-ld=lld

    # Sysroot containing aarch64-linux-gnu libraries to link against
    --sysroot=$JETSON_SYSROOT

    # CUDA libraries are here in sysroot from jetson
    -L$JETSON_SYSROOT/usr/local/cuda-10.2/targets/aarch64-linux/lib/

    # Custom build of OpenCV is installed here on jetson sysroot
    -L$JETSON_SYSROOT/opt/opencv-4.6.0/lib/
)

# Only to clang to compile C code
CFLAGS_ARR=(
    ${SHARED_FLAGS_ARR[@]}
)

# Only to clant++ to compile C++ code
CXXFLAGS_ARR=(
    ${SHARED_FLAGS_ARR[@]}
)

# To linker
LDFLAGS_ARR=(
    ${SHARED_FLAGS_ARR[@]}
)
################################################################################


################################################################################
# Environment setup
################################################################################
# Make sure any C/C++ code built by crates uses right compilers / flags
export CC=clang
export CXX=clang++
export CFLAGS="$(IFS=" "; echo "${CFLAGS_ARR[*]}")"
export CXXFLAGS="$(IFS=" "; echo "${CXXFLAGS_ARR[*]}")"
export LDFLAGS="$(IFS=" "; echo "${LDFLAGS_ARR[*]}")"
# Note: For C/C++ built by CMake, may need CMAKE_TOOLCHAIN_FILE variable
# and a custom toolchain file. Maybe not. It may respect these vars too.
################################################################################


################################################################################
# Cargo flags / tools setup for target
################################################################################
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=clang
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=llvm-ar
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS=""
for arg in "${SHARED_FLAGS_ARR[@]}"; do
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS -C link-args=$arg"
done
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="${CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS:1}"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS
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
