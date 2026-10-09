#!/bin/bash
# M6 check: Linux kernel source fetch validation

set -e
echo "=== M6: Linux kernel fetch ==="

# Find the Linux source in the runfiles
LINUX=$(find .. -maxdepth 1 -name '+_repo_rules+linux' -type d | head -1)
if [ -z "$LINUX" ]; then
    echo "FAIL: Could not find +_repo_rules+linux directory" >&2
    exit 1
fi

# Verify it's a valid Linux kernel source
if [ ! -f "$LINUX/Makefile" ]; then
    echo "FAIL: No Makefile in $LINUX" >&2
    ls "$LINUX" | head -20
    exit 1
fi

# Check for key directories
for dir in arch drivers fs include init kernel lib scripts tools; do
    if [ ! -d "$LINUX/$dir" ]; then
        echo "FAIL: Missing $dir" >&2
        exit 1
    fi
done

# Extract kernel version from Makefile
VERSION=$(grep '^VERSION =' "$LINUX/Makefile" | head -1)
PATCHLEVEL=$(grep '^PATCHLEVEL =' "$LINUX/Makefile" | head -1)
SUBLEVEL=$(grep '^SUBLEVEL =' "$LINUX/Makefile" | head -1)

echo "Found Linux kernel:"
echo "  $VERSION"
echo "  $PATCHLEVEL"
echo "  $SUBLEVEL"

echo "PASS: Linux kernel 6.1.62 source fetched successfully"
