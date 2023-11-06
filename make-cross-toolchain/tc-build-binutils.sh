#!/usr/bin/env bash

set -e

BINUTILS_VER=2.34
BINUTILS_NAME=binutils-${BINUTILS_VER}
BINUTILS_FILE=${BINUTILS_NAME}.tar.bz2

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
if [ ! -f $BINUTILS_FILE ]; then
    wget http://ftpmirror.gnu.org/binutils/${BINUTILS_FILE}
fi

# Clean extract sources
rm -rf $BINUTILS_NAME
tar xjfv $BINUTILS_FILE

# Build binutils using native host compiler (assumes building cross toolchain for this host)
# meaning canadian cross not supported here!
mkdir binutils-build
cd binutils-build

../$BINUTILS_NAME/configure \
    --with-sysroot=$SYSROOT \
    --target=aarch64-linux-gnu \
    --prefix=$TOOLCHAIN_DIR \
    --disable-nls \
    --enable-multilib \
    --with-gnu-as \
    --with-gnu-ld \
    --enable-languages=c,c++
make -j4 all
make install