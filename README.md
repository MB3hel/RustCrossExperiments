# RustCrossExperiments

Demo program for cross compiling rust (using OpenCV) from AMD64 linux host to Aarch64 jetson nano using sysroot and toolchain native to the host (targeting jetson).

Intended to be an alternative to building in a docker container or chroot using qemu user mode emulation.

## Setup & Compiling

TODO


## Making Toolchain

TODO


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
sudo cp make-cross-toolchain/convert-to-sysroot.sh $jetsonroot/root/
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
# Currently, only usr and opt are included in sysroot
# If other top level directories are added, include them too though!
tar -cvf sysroot.tar usr/ opt/

# xz will yield much better compression, but gzip will be faster
xz -z -T0 -v sysroot.tar
```


## Non-Linux host systems

Not supported (meaning I haven't made it work). It could, but there are some considerations. It's not trivial.

- Sysroot:
    - Uses unix symlinks. Should work on macos. Won't on windows
    - Would need to replace symlinks with copies for windows
    - This would make sysroot much larger.
- Toolchain:
    - Would need canadian cross compiler build process (host, target, and build systems all different)
    - I don't want to figure this out without using crosstool-ng
    - The problem with crosstool-ng is that you can't build it against an existing sysroot, which is necessary (kinda) in this case. Technically, you could have it make its own sysroot, but it may have linking issues with glibc / other builtin libs
    - It could be possible to build a toolchain with crosstool-ng with its own sysroot and just modify include / library paths to use real sysroot (but not actually use syroot flag). This would let gcc link against its own glibc. As long as glibc is same (or older) than used in real sysroot, it should be fine (gcc version should also probably be the same).
    - Better option would be to manually build canadian cross toolchain on Linux host using osxcross to have macos host and mingw-w64 to have windows host. Not really sure what this would entail. May just require adding --build flag? I may experiment with it eventually.
    - Another option could be to combine the jetson sysroot's libraries and includes with the crosstool-ng sysroot without overwriting crosstool-ng sysroot's files. This again *should* be fine with same glibc and gcc versions (or older glibc). Maybe this is cleaner overall? Just collect libraries from wherever they are on jetson image and merge into sysroot from ct-ng toolchain? Maybe easier? Maybe not though. have to look into what canadian cross entails.
