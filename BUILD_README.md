# Building and testing bone

Run everything from the repository root.

## Prerequisites

- Linux x86_64 host with Docker (the user must be able to run `docker`).
- Network access for the first build (Bazel fetches cosmocc 4.0.2 and busybox 1.36.1, both sha256-pinned).
- `./tools/bazel` bootstraps a pinned bazelisk and Bazel 8.5.1. No other install is needed.

## One-time setup

Build the container image used by the busybox actions:

```
docker build -t bone-build:1 docker/
```

## Hello-world (cosmocc check)

```
./tools/bazel test //tests/hello:hello_test --test_output=all
```

Expect `PASS: bone hello from Linux/x86_64`.

## Busybox

Generate the config (allnoconfig + `third_party/busybox/bone.fragment`):

```
./tools/bazel build //third_party/busybox:config
```

Build busybox for both architectures and fuse them:

```
./tools/bazel build //third_party/busybox:busybox
```

Outputs, under `$(./tools/bazel info bazel-bin)/third_party/busybox/`:

| File | Description |
|---|---|
| `busybox.x86_64.elf` | x86_64 static ELF (use this one) |
| `busybox.aarch64.elf` | aarch64 static ELF |
| `busybox.com` | fused APE; needs the APE loader, which fails on some hosts |

The busybox actions are tagged `local` and `no-cache` because they call `docker`, so they re-run on every build.

## Test

```
./tools/bazel test //tests/busybox:busybox_test --test_output=all
```

Expect `PASS: busybox applets run (x86_64)`. The test checks the ELF machine type of both files and, on a Linux x86_64 host, runs `--list`, `echo`, `sort` and `uname -m`.

## Run by hand

The applet is chosen from `argv[0]`, so the file must be named `busybox`.

```
D=$(./tools/bazel info bazel-bin)/third_party/busybox
mkdir -p /tmp/t && cp $D/busybox.x86_64.elf /tmp/t/busybox && chmod +x /tmp/t/busybox
/tmp/t/busybox --list
/tmp/t/busybox uname -m
printf 'b\na\n' | /tmp/t/busybox sort
file $D/busybox.aarch64.elf    # header check only; cannot run on x86_64
```

## Adding an applet

1. Add `CONFIG_<NAME>=y` to `third_party/busybox/bone.fragment`.
2. Rebuild `//third_party/busybox:busybox` and check the applet in `--list`.
3. If it fails to compile (usually a missing `linux/*.h`, which cosmo's libc lacks), remove it from the fragment.

On failure the build script prints the last 40 lines of the make log.

## Troubleshooting

- `Exec format error` from `./tools/bazel`: `tools/bazelisk` is for another OS. Delete it and rerun.
- `bazel-*` symlink warnings: stale links from another host. Run `rm -rf bazel-bin bazel-out bazel-bone bazel-testlogs`.
- `Unable to find image 'bone-build:1'`: run the `docker build` step above.
- Fresh start: `./tools/bazel clean`, then rebuild.

## How it works

See `docs/DESIGN.md` (decisions for M3 and M5) and `docs/LOG.md` (per-milestone results).
