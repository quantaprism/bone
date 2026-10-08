#!/bin/sh
# Fetch bazelisk into tools/ with a pinned checksum. Run once; tools/bazel calls it if needed.
set -eu
VER=v1.29.0
dir=$(cd "$(dirname "$0")" && pwd)
os=$(uname -s | tr A-Z a-z); arch=$(uname -m)
case "$arch" in x86_64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; esac
case "$os-$arch" in
  darwin-arm64) sha=cee851f726789227d5561004e9904a52be45c3efb56f8b38b6993d6adbaa0409 ;;
  *) sha="" ;;  # TODO: add checksums for other hosts when first used
esac
out="$dir/bazelisk"
[ -x "$out" ] && exit 0
curl -fsSL -o "$out" "https://github.com/bazelbuild/bazelisk/releases/download/$VER/bazelisk-$os-$arch"
if [ -n "$sha" ]; then
  echo "$sha  $out" | shasum -a 256 -c - >/dev/null || { rm -f "$out"; echo "bazelisk checksum mismatch" >&2; exit 1; }
else
  echo "warning: no pinned checksum for $os-$arch" >&2
fi
chmod +x "$out"
