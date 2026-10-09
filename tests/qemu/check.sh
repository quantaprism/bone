#!/bin/bash
# M9 validation: QEMU boot test framework check

set -e

echo "=== M9: QEMU boot test validation ==="

# Check for required tools (optional - framework should work anyway)
for tool in qemu-system-x86_64 qemu-system-aarch64; do
    if ! command -v "$tool" &> /dev/null; then
        echo "WARN: $tool not found (optional for M9 placeholder)"
    fi
done

# Find test script in Bazel runfiles
TEST_SCRIPT=""
for f in "${@}"; do
    if [ -f "$f" ] && grep -q "bone QEMU Boot Test" "$f" 2>/dev/null; then
        TEST_SCRIPT="$f"
        break
    fi
done

# If not found in args, search current directory
if [ -z "$TEST_SCRIPT" ]; then
    if [ -f "qemu_boot_test.sh" ]; then
        TEST_SCRIPT="qemu_boot_test.sh"
    elif [ -f "./qemu_boot_test.sh" ]; then
        TEST_SCRIPT="./qemu_boot_test.sh"
    fi
fi

if [ -z "$TEST_SCRIPT" ] || [ ! -f "$TEST_SCRIPT" ]; then
    echo "FAIL: Test script not found" >&2
    exit 1
fi

if [ ! -x "$TEST_SCRIPT" ]; then
    echo "FAIL: Test script not executable: $TEST_SCRIPT" >&2
    exit 1
fi

# Test script help
if ! "$TEST_SCRIPT" --help | grep -q "bone QEMU Boot Test"; then
    echo "FAIL: Test script help not working" >&2
    exit 1
fi

# Show test script info
echo "Test script: $TEST_SCRIPT"
ls -lh "$TEST_SCRIPT"

echo ""
echo "PASS: M9 QEMU boot test framework validated"
echo "  - Framework structure: OK"
echo "  - Script executable: OK"
echo "  - Help/options: working"
echo ""
echo "Status: M9 framework ready for M9-extended implementation"
echo "Requires: rootfs.img + Linux bzImage from M7-extended"
echo "Optional: QEMU KVM acceleration for faster testing"
