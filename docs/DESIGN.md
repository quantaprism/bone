# bone — design

`bone` is a minimal network-OS image, built with Bazel and packaged as an ONIE installer.
This document is the plan. Every milestone below is one commit (or a short series) with a
**check** that must pass before the next milestone starts.

## Scope (for now)

In: Bazel build of busybox using the Cosmopolitan toolchain (`cosmocc`), then a rootfs,
then an ONIE installer, tested under QEMU.
Out (later): syncd/SAI over gRPC, orchestrator, FRR, PMON.

## Key decisions

| Decision | Choice | Why |
|---|---|---|
| Build system | Bazel 8.5.1 + bzlmod | Same version as sonic-swss-common, so `bone` can later reuse sonic-build-infra |
| Compiler | `cosmocc` (pinned, sha256-verified) | One fat APE binary holds x86_64 + aarch64 |
| Busybox | pinned release tarball, sha256-verified, config fragment kept in repo | Reproducible applet set |
| Multi-arch | inside the toolchain (cosmocc), not Bazel platform transitions | cosmocc builds both arches in one invocation |
| Packaging | rules_pkg tar -> squashfs rootfs -> sharch ONIE installer | Mirrors SONiC's installer layout |
| Test | QEMU + ONIE KVM image | No hardware needed |

## Decision (M3): no registered cc_toolchain

cosmocc builds both architectures in one invocation and leaves per-arch intermediates next to the
output. A split compile/link `cc_toolchain` would lose them in Bazel's sandbox, so cosmocc is used
through `cosmo_cc_binary` (compile + link in one declared-output action). Busybox (M5) follows the
same pattern: one action runs the whole make. A real `cc_toolchain` can come later if needed.

## Decision (M5): per-arch builds in Docker, then apelink

Busybox's kbuild partial-links with `$(CC) -nostdlib -r`, which the fat `cosmocc` wrapper rejects. So busybox is built
twice, once per arch, with `ARCH-unknown-cosmo-cc` / `ARCH-linux-cosmo-ld`, inside the `bone-build` Docker image
(`docker/Dockerfile`, Debian bookworm + make/gcc/bzip2; host tools such as kconfig use its gcc). `apelink` then fuses the two
ELFs. Build actions are tagged `local` because they call `docker`.

- No busybox source patches. `third_party/busybox/bone_linux_consts.h` is force-included (`CONFIG_EXTRA_CFLAGS`) and pins the
  Linux values of signals and AF_/SOCK_ constants, which cosmo otherwise resolves at runtime. It also adds a label to asm files
  whose body is `#if`-ed out (cosmocc rejects symbol-less objects). Valid because bone is Linux-only.
- Config is `allnoconfig` + `bone.fragment`, not `defconfig`: cosmo's libc has no `linux/*.h`, so most networking and
  util-linux applets cannot build. Applets are added to the fragment one at a time as they are verified.
- Risk 4 outcome: the fused APE `.com` needs the APE loader (`~/.ape-*`) which failed on the Linux host and in the container.
  The per-arch plain ELFs (`busybox.x86_64.elf`, `busybox.aarch64.elf`) run directly, so the image uses those.

## Known risks (verified at the milestone that exercises them)

1. Busybox may not build cleanly under cosmocc for every applet. M3 finds the working set;
   unsupported applets are removed in the config fragment, not patched.
2. cosmocc tools are APE binaries. On Linux hosts without binfmt they need `assimilate` or the
   APE loader to run hermetically. M2 records what the sandbox needs.
3. The build host is macOS arm64 and busybox's build system assumes GNU tools. M3 decides between
   building natively on macOS (with cosmocc's bundled tools) or in a Linux VM/container, and
   records the decision here.
4. An APE binary is not an ELF file. M5 checks that the kernel in the final image can exec it
   (or that it has been `assimilate`d to a plain per-arch ELF).

## Milestones

| # | Commit | Check |
|---|---|---|
| 0 | Design doc + repo skeleton | Doc reviewed |
| 1 | Bazel scaffold: `.bazelversion`, `MODULE.bazel`, `.bazelrc`, a trivial target | `bazel build //...` succeeds on a clean checkout |
| 2 | Fetch cosmocc with `http_archive` (pinned sha256) | `bazel run //toolchains:cosmocc_version` prints the expected version |
| 3 | `cosmo_cc_binary` rule (single-action cosmocc) + hello-world | `bazel test //tests/hello:hello_test`: runs, and both x86_64 and aarch64 ELF payloads present |
| 4 | Fetch busybox source + `defconfig`-derived config fragment | Config generation is deterministic (same hash on two runs) |
| 5 | Build busybox with the cosmo toolchain | `busybox --list` works; chosen applets execute |
| 6 | Smoke test target (`bazel test`) for the applets | Test passes in CI mode |
| 7 | Rootfs tar + squashfs | Squashfs lists expected tree; reproducible hash |
| 8 | ONIE installer (sharch) | Installer self-checksum verifies; payload extracts |
| 9 | QEMU + ONIE KVM test | `onie-nos-install` completes; image boots to busybox shell |

Each milestone ends with a short entry in `docs/LOG.md`: what changed, what was verified, and any
decision that changed this plan.

## Layout

```
bone/
  MODULE.bazel  .bazelrc  .bazelversion
  toolchains/   cosmocc fetch + cc_toolchain
  third_party/  busybox (source, config fragment)
  rootfs/       tar / squashfs rules
  onie/         installer template + sharch rule
  tests/        smoke tests
  docs/         DESIGN.md, LOG.md
```
