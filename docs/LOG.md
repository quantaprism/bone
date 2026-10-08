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
