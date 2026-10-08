#!/bin/sh
# In container. Mounts: /src busybox (ro), /cosmocc (ro), /config, /consts.h, /out (rw).
# Builds one ELF per arch with the cosmo cross tools, then fuses them into one APE with apelink.
set -eu
export PATH=/cosmocc/bin:$PATH
for a in x86_64 aarch64; do
  w=/tmp/build-$a
  rm -rf "$w"; cp -r /src "$w"; chmod -R u+w "$w"
  cp /config "$w/.config"
  make -C "$w" -j"$(nproc)" V=0 \
    CONFIG_EXTRA_CFLAGS="-include /consts.h" \
    CC=$a-unknown-cosmo-cc LD=$a-linux-cosmo-ld AR=$a-unknown-cosmo-ar \
    STRIP=$a-unknown-cosmo-strip HOSTCC=gcc busybox >/tmp/build-$a.log 2>&1 \
    || { tail -40 /tmp/build-$a.log >&2; exit 1; }
  cp "$w/busybox_unstripped" /out/busybox.$a.elf
done
apelink -V 0 -l /cosmocc/bin/ape-x86_64.elf -l /cosmocc/bin/ape-aarch64.elf -M /cosmocc/bin/ape-m1.c \
  -o /out/busybox /out/busybox.x86_64.elf /out/busybox.aarch64.elf
