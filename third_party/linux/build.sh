#!/bin/bash
# Build Linux 6.1.62 kernel for bone project
# Usage: build.sh <arch> <output-dir>
# Runs in Docker container with @linux source already in stdin or accessible

set -ex

ARCH="${1:?Architecture required (x86_64 or aarch64)}"
OUTPUT_DIR="${2:?Output dir required}"

# The Linux source should already be in /linux (will be set up by genrule)
LINUX_SRC="/linux"

if [ ! -f "$LINUX_SRC/Makefile" ]; then
    echo "ERROR: $LINUX_SRC/Makefile not found" >&2
    exit 1
fi

cd "$LINUX_SRC"

# Normalize arch name for Linux Makefile
case "$ARCH" in
    x86_64)
        KARCH="x86"
        CROSS_COMPILE=""
        ;;
    aarch64)
        KARCH="arm64"
        CROSS_COMPILE="aarch64-linux-gnu-"
        # Install arm64 cross-compiler in docker if needed
        apt-get update -qq && apt-get install -y -qq gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu > /dev/null 2>&1 || true
        ;;
    *)
        echo "Unsupported arch: $ARCH" >&2
        exit 1
        ;;
esac

echo "Building Linux kernel for $ARCH (KARCH=$KARCH)..."

# Start with allnoconfig
make ARCH="$KARCH" allnoconfig >/dev/null 2>&1

# Append bone config options
cat >> .config << 'BONE_CONFIG'
CONFIG_64BIT=y
CONFIG_X86_64=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_RD_GZIP=y
CONFIG_CONSOLE_LOGLEVEL_DEFAULT=7
CONFIG_PRINTK=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_VT=y
CONFIG_VT_CONSOLE=y
CONFIG_EXT4_FS=y
CONFIG_EXT4_FS_POSIX_ACL=y
CONFIG_PROC_FS=y
CONFIG_SYSFS=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_UNIX=y
CONFIG_INET=y
CONFIG_UEVENT_HELPER=y
BONE_CONFIG

# Normalize config (answer defaults for new options)
yes "" | make ARCH="$KARCH" CROSS_COMPILE="$CROSS_COMPILE" oldconfig >/dev/null 2>&1 || true

echo "Compiling kernel..."
# Build kernel (suppress most output, only show errors and final lines)
make -j$(nproc) ARCH="$KARCH" CROSS_COMPILE="$CROSS_COMPILE" bzImage 2>&1 | grep -E 'error|warning|Built|bzImage' | tail -20 || true

# Find and copy bzImage
BZIMAGE=$(find arch -name bzImage -type f | head -1)
if [ -z "$BZIMAGE" ] || [ ! -f "$BZIMAGE" ]; then
    echo "ERROR: bzImage not found after build" >&2
    ls -la arch/*/boot/
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
cp "$BZIMAGE" "$OUTPUT_DIR/bzImage"
echo "SUCCESS: Linux 6.1.62 ($ARCH) bzImage -> $OUTPUT_DIR/bzImage"
ls -lh "$OUTPUT_DIR/bzImage"
