#!/bin/sh
# Verify the cosmo hello binary runs and carries both architecture payloads.
set -eu
hello=$1; x86=$2; arm=$3
out=$("$hello")
case "$out" in "bone hello from "*) ;; *) echo "unexpected output: $out" >&2; exit 1 ;; esac
# ELF e_machine (2 bytes at offset 18, little endian): x86_64=0x3e, aarch64=0xb7.
machine() { od -An -tx1 -j18 -N2 "$1" | tr -d ' \n'; }
[ "$(machine "$x86")" = "3e00" ] || { echo "x86_64 payload wrong: $(machine "$x86")" >&2; exit 1; }
[ "$(machine "$arm")" = "b700" ] || { echo "aarch64 payload wrong: $(machine "$arm")" >&2; exit 1; }
echo "PASS: $out"
