#!/bin/sh
# Usage: dockerrun.sh <mounts...> -- cmd...   (mounts are docker -v specs). Runs in the bone-build image as the caller.
set -eu
args=""
while [ "$1" != "--" ]; do args="$args -v $1"; shift; done
shift
exec docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e TMPDIR=/tmp $args bone-build:1 "$@"
