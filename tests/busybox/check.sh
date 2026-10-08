#!/bin/sh
# Args: x86_64 ELF, aarch64 ELF. The x86_64 binary is executed only on Linux x86_64 hosts.
set -eu
x86=$1; arm=$2
mach() { od -An -tx1 -j18 -N2 "$1" | tr -d ' \n'; }
[ "$(mach "$x86")" = "3e00" ] || { echo "x86_64 e_machine wrong"; exit 1; }
[ "$(mach "$arm")" = "b700" ] || { echo "aarch64 e_machine wrong"; exit 1; }
if [ "$(uname -sm)" = "Linux x86_64" ]; then
  d=$(mktemp -d); cp "$x86" "$d/busybox"; chmod +x "$d/busybox"
  list=$("$d/busybox" --list)
  for a in cat ls echo sort uname; do echo "$list" | grep -qx "$a" || { echo "missing applet $a"; exit 1; }; done
  [ "$("$d/busybox" echo hi)" = "hi" ] || exit 1
  [ "$(printf 'b\na\n' | "$d/busybox" sort | tr -d '\n')" = "ab" ] || exit 1
  [ "$("$d/busybox" uname -m)" = "x86_64" ] || exit 1
  echo "PASS: busybox applets run (x86_64)"
else
  echo "PASS: ELF headers only (host cannot run x86_64)"
fi
