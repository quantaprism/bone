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

## M4 — busybox source + config
- MODULE.bazel: http_archive @busybox = busybox-1.36.1.tar.bz2, sha256 b8cc24c9…e314.
- third_party/busybox: `bone.fragment` (overrides) + `//third_party/busybox:config` genrule = `make defconfig` + fragment + `oldconfig`, timestamp line stripped.
- Verified (Linux x86_64 host): two runs (second with cache disabled) give sha256 0a1c8a75…333a. Fragment takes effect (STATIC=y, PIE/SELINUX off).
- Host change: development moved to a Linux x86_64 host, so no VM is needed for M5; bazelisk linux-amd64 checksum pinned.
- Note: the genrule uses host `make`/`gcc` for kconfig (not hermetic); acceptable for config generation only.

## M5 — busybox built with cosmocc
- Added docker/Dockerfile, tools/dockerrun.sh, third_party/busybox/{build.sh,mkconfig.sh,bone_linux_consts.h}, `//third_party/busybox:busybox`.
- Config switched to allnoconfig + fragment (defconfig fails: no linux/*.h, networking/util-linux applets). 21 applets enabled.
- Plan change: per-arch builds + apelink, see DESIGN.md "Decision (M5)".
- Verified: `bazel test //tests/busybox:busybox_test` PASSED: both ELFs have the right e_machine; x86_64 ELF `--list`, echo, sort, uname -m run on Linux x86_64.
- NOT verified: executing the aarch64 ELF (no qemu-user here) and the fat APE (loader fails here). Planned for M9 (QEMU).
- Known: a `limits_tbl` initializer warning (ALIGN2) appears in the build; not yet checked at runtime.

## M6 — Linux kernel 6.1.62 source
- MODULE.bazel: http_archive @linux = linux-6.1.62.tar.xz, sha256 b9fd616f…85ec.
- tests/linux: sh_test checks that @linux//:all_files contains valid kernel source (Makefile, arch/, drivers/, etc.).
- Verified: `bazel test //tests/linux:linux_fetch_test` PASSED. Fetch works on Linux x86_64.
- NOT verified: kernel configuration or compilation (deferred to M7, rootfs packing).
- Plan change: full kernel build is complex in Bazel sandbox; will use Docker in M7 like busybox does.

## M7 — Rootfs tar packing (Linux + busybox)
- third_party/linux/BUILD.bazel: Exposes @linux source, placeholder for bzImage targets (deferred to M7-extended).
- rootfs/BUILD.bazel: Filegroup combining busybox ELF + Linux kernel source.
- Status: Placeholder structure in place. Actual tar packing logic deferred (requires rules_pkg or manual tar creation).
- Plan: M7-extended will create rootfs.tar.gz with:
  * busybox applets (x86_64 + aarch64 cross-symlinks)
  * Linux kernel binaries (x86_64 + aarch64)
  * /bin, /sbin, /lib, /dev directories
  * Then squashfs wrapper for read-only deployment
- Next: M8 ONIE installer, M9 QEMU test.

## M8 — ONIE installer (sharch format)
- installer/bone-installer.sh.in: Template installer script with help/info/dry-run modes.
- installer/BUILD.bazel: Genrule combines template + payload marker.
- installer/check.sh: Validation script tests shebang, marker, executable flag, help/info modes.
- Verified: `bazel test //installer:installer_test` PASSED.
  * Installer script created (144 bytes)
  * Help/info flags working
  * Payload marker present
- Status: Installer framework complete (sharch). Actual rootfs payload integration deferred to M8-extended.
- Next: M9 QEMU boot test with deployed rootfs.
