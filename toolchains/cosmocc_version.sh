#!/bin/sh
# Print the cosmocc version from the Bazel-fetched toolchain.
set -eu
root=$(dirname "$(dirname "$(find -L "${RUNFILES_DIR:-$0.runfiles}" -path '*/cosmocc*/bin/cosmocc' -print -quit)")")
"$root/bin/cosmocc" --version | head -1
