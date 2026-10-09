#!/bin/bash
# M8 validation: ONIE installer sharch format check

set -e

INSTALLER="${1:?Installer path required}"

echo "=== M8: ONIE installer validation ==="

if [ ! -f "$INSTALLER" ]; then
    echo "FAIL: Installer not found at $INSTALLER" >&2
    exit 1
fi

if [ ! -x "$INSTALLER" ]; then
    echo "FAIL: Installer not executable" >&2
    exit 1
fi

# Check shebang
if ! head -1 "$INSTALLER" | grep -q '^#!/bin/bash'; then
    echo "FAIL: Invalid shebang (expected #!/bin/bash)" >&2
    exit 1
fi

# Check for payload marker
if ! grep -q "^##_PAYLOAD_MARKER_##$" "$INSTALLER"; then
    echo "FAIL: Payload marker not found" >&2
    exit 1
fi

# Test --info flag
if ! "$INSTALLER" --info | grep -q "bone ONIE Installer"; then
    echo "FAIL: --info flag not working" >&2
    exit 1
fi

# Test --help flag
if ! "$INSTALLER" --help | grep -q "ONIE-compatible installer"; then
    echo "FAIL: --help flag not working" >&2
    exit 1
fi

# Get file size
SIZE=$(stat -c%s "$INSTALLER")
echo "Installer created: $INSTALLER ($SIZE bytes)"

echo "PASS: bone ONIE installer (sharch) created successfully"
echo "  - Shebang: #!/bin/bash"
echo "  - Payload marker: ##_PAYLOAD_MARKER_##"
echo "  - Help/info flags: working"
