#!/bin/sh
# In container: /w = writable busybox tree, /frag = fragment. Writes /w/.config (no timestamp).
set -eu
cd /w
make -s allnoconfig >/dev/null 2>&1
grep -v '^#' /frag | while read -r l; do
  k=${l%%=*}
  sed -i "/^# $k is not set/d;/^$k=/d" .config
  echo "$l" >> .config
done
yes '' | make -s oldconfig >/dev/null 2>&1 || true
grep -v -E '^# [A-Z][a-z]{2} [A-Z][a-z]{2} ' .config > /w/.config.clean
