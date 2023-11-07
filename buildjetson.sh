#!/usr/bin/env sh

################################################################################
# Setup
################################################################################
# Default value if not specified via env var
[ -z "$JETSON_SYSROOT" ] && JETSON_SYSROOT=$HOME/sysroot-jetson
################################################################################


################################################################################
# Flags passed to clang
################################################################################
# Passed to everything (c, c++, linker)
shared_flags="-target aarch64-linux-gnu"                                                            # Tells clang to compile for aarch64 linux
shared_flags="$shared_flags -mcpu=cortex-a57"                                                       # Jetson CPU
shared_flags="$shared_flags -fuse-ld=lld"                                                           # Use lld b/c it supports -target
shared_flags="$shared_flags --sysroot=$JETSON_SYSROOT"                                              # Specify sysroot
shared_flags="$shared_flags -L$JETSON_SYSROOT/usr/local/cuda-10.2/targets/aarch64-linux/lib/"       # CUDA is here on jetson sysroot
shared_flags="$shared_flags -L$JETSON_SYSROOT/opt/opencv-4.6.0/lib/"                                # Custom OpenCV is here on jetson sysroot

# Only to clang to compile C code
cflags="$shared_flags"

# Only to clant++ to compile C++ code
cxxflags="$shared_flags"

# To linker (and rustflags as link-args)
ldflags="$shared_flags"
################################################################################


################################################################################
# Environment setup
################################################################################
# Make sure any C/C++ code built by crates uses right compilers / flags
export CC=clang
export CXX=clang++
export AR=llvm-ar
export CFLAGS="$cflags"
export CXXFLAGS="$cxxflags"
export LDFLAGS="$ldflags"
# Note: For C/C++ built by CMake, may need CMAKE_TOOLCHAIN_FILE variable
# and a custom toolchain file. Maybe not. It may respect these vars too.
################################################################################


################################################################################
# Cargo flags / tools setup for target
################################################################################
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=clang
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_AR=llvm-ar
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS=""
for arg in $(echo $ldflags | sed 's/ /\n/g'); do
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="$CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS -C link-args=$arg"
done
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS="${CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS#?}"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUSTFLAGS
################################################################################


################################################################################
# OpenCV stuff
################################################################################
# Ensures correct OpenCV found (using environment var search method)
OPENCV_LINK_LIBS=""
for lib in $(find $JETSON_SYSROOT/opt/opencv-4.6.0/lib/ -name "*.so" -maxdepth 1); do
    lib_name=$(basename $lib)
    lib_name=${lib_name#???}        # Remove first 3 chars ("lib")
    lib_name=${lib_name%???}        # Remove final 3 chars (".so")
    OPENCV_LINK_LIBS="$OPENCV_LINK_LIBS,$lib_name"
done
OPENCV_LINK_LIBS="${OPENCV_LINK_LIBS#?}"
export OPENCV_LINK_LIBS
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
