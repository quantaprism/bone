# bone log

One entry per milestone: what changed, what was verified, plan changes.

## M0 — design and skeleton
- Added docs/DESIGN.md (plan, risks, milestones).
- Verified: n/a (docs only).
- Host facts: macOS arm64, no Bazel, no Docker, network reachable (cosmo.zip, busybox.net).

## M1 — Bazel scaffold
- Added .bazelversion (8.5.1), MODULE.bazel, .bazelrc, placeholder //:hello genrule.
- tools/bazel + tools/get-bazelisk.sh bootstrap bazelisk v1.29.0 with a pinned sha256 (darwin-arm64 only so far;
  other hosts print a warning until their checksum is added). The binary itself is git-ignored.
- Finding: bazelisk ignores .bazelversion until MODULE.bazel exists (it picked 9.3.0 before).
- Verified: `./tools/bazel build //...` succeeds with Bazel 8.5.1 (see clean-clone check below).

## M2 — pinned cosmocc fetch
- MODULE.bazel: http_archive @cosmocc = cosmocc-4.0.2.zip, sha256 85b8c37a…3f44 (442 MB).
- //toolchains:cosmocc_version runs the fetched cosmocc.
- Verified: `./tools/bazel run //toolchains:cosmocc_version` -> "cosmocc (GCC) 14.1.0" on macOS arm64.
- Note: the APE compiler runs on macOS arm64 from the Bazel external repo with no extra setup, but this
  was a non-sandboxed `run`. Sandboxed actions (M3) may need HOME/ape-loader handling; recorded as risk 2.

## M3 — cosmocc as a hermetic action + hello-world
- Added toolchains/cosmo.bzl (`cosmo_cc_binary`), tests/hello (C source, per-arch filegroups, sh_test).
- Plan change: no registered cc_toolchain (see DESIGN.md "Decision (M3)").
- cosmocc output files: `<out>` (APE), `<out>.com.dbg` (x86_64 ELF), `<out>.aarch64.elf` (aarch64 ELF).
- Verified: sandboxed build works on macOS arm64 (HOME/TMPDIR pointed at a temp dir, no loader issues);
  `bazel test //tests/hello:hello_test` PASSED (runs; e_machine 0x3e and 0xb7 payloads present).
- NOT verified: executing the x86_64 payload. `arch -x86_64 ./hello` still ran the arm64 side on macOS.
  x86_64 execution is covered in the Linux VM / QEMU milestones.
- Lima 2.2.1 installed via Homebrew for the Linux build environment (M5).
