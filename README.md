# RustCrossExperiments

Demo program for cross compiling rust (using OpenCV) from AMD64 linux host to Aarch64 jetson nano using sysroot and toolchain native to the host (targeting jetson).

Intended to be an alternative to building in a docker container or chroot using qemu user mode emulation.

## Required tools

clang, the lld linker, and rust (rustc, rustup, cargo) are required. Additionally, you will need a posix shell.

Install on windows using [scoop](https://scoop.sh/)

```sh
# llvm provides clang and lld
# Busybox provides posix compatible sh
scoop install llvm rustup busybox

# Install rust using rustup-init
curl -L https://win.rustup.rs/x86_64 -o rustup-init.exe
.\rustup-init.exe
```

Install on macOS using

```sh
# clang and lld should be available on macos by default
# May need to install xcode developer tools though using xcode-select --install
# And a posix shell exists (dash, bash, zsh)
# So just need to install rust 
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Install on Ubuntu

```sh
# Installs llvm, clang, and lld using system package manager
# Installs rust using official rustup script
sudo apt install llvm lld clang
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```


## Setup Sysroot 

A sysroot for the target system is also required (any OS). This provides headers and libraries for the target system. See instructions below on making a sysroot from a OS image if you don't have one already.

It is assumed that the sysroot is a compressed tar archive (likely `.tar.xz`). On windows, run in busybox sh. It is recommended to extract to `$HOME/sysroot-jetson` on all systems. If extracting somewhere else, you will need to set the JETSON_SYSROOT environment variable.

```sh
# WARNING: This first command deletes $HOME/sysroot-jetson if it exists!
rm -rf $HOME/sysroot-jetson
mkdir $HOME/sysroot-jetson
tar -xvf sysroot-jetson.tar.xz -C $HOME/sysroot-jetson
```

## Building for Jetson

```sh
# Clean old builds for jetson
./cleanjetson.sh

# Perform the build
./buildjetson.sh
```

Resultant binary will be `target-jetson/aarch64-unknown-linux-gnu/debug/opencv_test`.

How it works:

- Part 1: C/C++ cross compiler
    - clang is natively a cross compiler. Thus, it can produce code for aarch64 linux, but needs a sysroot to provide libraries to link to
    - The sysroot created from the jetson image has the libraries for clang to link to. This includes all libraries from the jetson image.
    - Clang will link to the same glibc / libstdc++ as are on the jetson the code will run on
    - To make this work, clang is given the `-target aarch64-linux-gnu` and `--sysroot=` arguments. Some additional include paths in the sysroot (non-default, but jetson specific) are supplied using `-L` arguments too.
    - A cross compiler GNU GCC toolchain could have been built instead, but that is a complex process (would require building binutils and gcc against existing sysroot) and requires a different toolchain per supported host. By using clang, you just need clang to have "native" support for the host you are using to build.
    - The build script sets various environment variables to ensure the correct programs and flags are used by any nested C code builds.
- Part 2: Linker
    - Clang's lld supports the `-target` flat just like clang. In other words, it is natively a cross linker.
    - Once again, a cross compiler GNU GCC toolchain could have provided `gcc` as a linker, but this has the same challenges described previously.
    - Really, the linker is all that is strictly required for rust code. The C/C++ toolchain is needed for some dependencies (that build / generate bindings to native c libraries, eg opencv).
    - Using lld is done by specifying clang as the linker and using the `-fuse-ld=lld`
    - Clang is specified as the linker for the `aarch64-unknown-linux-gnu` target.
    - Rust is provided with the rustflags `-C link-args=[arg]` for each `arg` described for clang in the last two sections. This ensures that when rust invokes `clang` as the linker, it will use lld with the correct target and sysroot / library search path arguments.
    - Rust linker and flags are provided using environment vars not `.config/config.toml` since a script is necessary anyway. These same arguments have to be set to some environment variables as described in part 1.
- Part 3: OpenCV
    - The OpenCV bindings generator doesn't play nice with the sysroot without some help
    - The explicit path to opencv install (a custom build in this case since CUDA / cuDNN support was required) is provided in the build script
    - This requires using environment variables to disable other search methods for the opencv bindings generator. It also requires generating a list of all opencv libraries.


## Making Sysroot

Assuming you have a Jetson nano os image named `jetson.img`.

Mount the image and setup for chroot

```sh
jetsonroot=/mnt/jetsonroot

loopdev=`sudo losetup -f -P --show jetson.img`
sudo mkdir $jetsonroot
sudo mount ${loopdev}p1 $jetsonroot

sudo mount --rbind /dev $jetsonroot/dev
sudo mount --make-rslave $jetsonroot/dev
sudo mount --bind /sys $jetsonroot/sys
sudo mount --bind /proc $jetsonroot/proc
```

Make a folder on the host  accessible on the chroot as `/mnt/sysroot`

```sh
sysrootdest=$HOME/sysroot
mkdir $sysrootdest
mkdir $jetsonroot/mnt/sysroot
sudo mount --bind $sysrootdest $jetsonroot/mnt/sysroot
```

Copy the convert-to-sysroot script to the chroot

```sh
sudo cp convert-to-sysroot.sh $jetsonroot/root/
```

Enter the chroot and run the script. This script will copy necessary files, fix symlinks to be relative (so they are useable in a portable sysroot), the report any broken links remaining (many of these won't need to be fixed because they linked to things that were intentionally omitted or they were broken to begin with).

```sh
# Make sure qemu-user-static is installed first if your system isn't aarch64
sudo chroot $jetsonroot

# Now in chroot
cd /root
./convert-to-sysroot.sh /mnt/sysroot

# Once script is done, exit chroot
exit
```

The sysroot folder is now available on your host system. You can unmount jetson image now.

```sh
sudo umount -R $jetsonroot
```

Then, pack an archive of the sysroot. The sysroot will probably be quite large (CUDA is very large), so compression may take a little while.

```sh
tar -cvf sysroot-jetson.tar *
xz -z -T0 -v sysroot-jetson.tar
```
