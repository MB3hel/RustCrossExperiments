#!/usr/bin/env bash

set -e

GCC_VER=9.4.0
GCC_NAME=gcc-${GCC_VER}
GCC_FILE=${GCC_NAME}.tar.xz

if [ -z "$SYSROOT" ]; then
    echo "Must set SYSROOT first!"
    exit 1
fi
if [ ! -d "$SYSROOT" ]; then
    echo "SYSROOT directory does not exist!"
    exit 1
fi

if [ -z "$TOOLCHAIN_DIR" ]; then
    echo "Must set TOOLCHAIN_DIR first!"
    exit 1
fi

# Download source if needed
if [ ! -f $GCC_FILE ]; then
    wget https://bigsearcher.com/mirrors/gcc/releases/$GCC_NAME/$GCC_FILE
fi

# Clean extract sources
rm -rf $GCC_NAME
tar xJfv $GCC_FILE

cd $GCC_NAME
./contrib/download_prerequisites
cd ..

# Build binutils using native host compiler (assumes building cross toolchain for this host)
# meaning canadian cross not supported here!
rm -rf gcc-build
mkdir gcc-build
cd gcc-build

../$GCC_NAME/configure \
    --target=aarch64-linux-gnu \
    --prefix=$TOOLCHAIN_DIR \
    --disable-nls \
    --with-gnu-as \
    --with-gnu-ld \
    --with-sysroot=$SYSROOT
make -j4 all
make install