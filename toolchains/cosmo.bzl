"""Rules that run cosmocc as one hermetic action.

cosmocc compiles every translation unit for x86_64 and aarch64 in the same invocation and
writes per-arch intermediates (`.aarch64/` objects, `<out>.com.dbg`, `<out>.aarch64.elf`) next to the output. Bazel's sandbox
drops undeclared outputs, so a split compile/link cc_toolchain cannot work. Instead each rule
here does compile + link in a single action and declares every file it produces.
"""

def _cosmo_cc_binary_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name)
    dbg_x86 = ctx.actions.declare_file(ctx.label.name + ".x86_64.elf")
    dbg_arm = ctx.actions.declare_file(ctx.label.name + ".aarch64.elf")
    cosmocc = ctx.file._cosmocc
    ctx.actions.run_shell(
        outputs = [out, dbg_x86, dbg_arm],
        inputs = depset(ctx.files.srcs + ctx.files.hdrs, transitive = [ctx.attr._toolchain_files.files]),
        command = """
set -eu
tmp=$(mktemp -d)
export TMPDIR="$tmp" HOME="$tmp"
work="$tmp/out"; mkdir -p "$work"
"{cosmocc}" {copts} -o "$work/{name}" {srcs}
cp "$work/{name}" "{out}"
cp "$work/{name}.com.dbg" "{dbg_x86}"
cp "$work/{name}.aarch64.elf" "{dbg_arm}"
rm -rf "$tmp"
""".format(
            cosmocc = cosmocc.path,
            copts = " ".join(ctx.attr.copts),
            name = ctx.label.name,
            srcs = " ".join([f.path for f in ctx.files.srcs]),
            out = out.path,
            dbg_x86 = dbg_x86.path,
            dbg_arm = dbg_arm.path,
        ),
        mnemonic = "CosmoCc",
        progress_message = "cosmocc (x86_64 + aarch64) %s" % ctx.label,
    )
    return [DefaultInfo(
        files = depset([out]),
        executable = out,
        runfiles = ctx.runfiles(files = [dbg_x86, dbg_arm]),
    ), OutputGroupInfo(x86_64 = depset([dbg_x86]), aarch64 = depset([dbg_arm]))]

cosmo_cc_binary = rule(
    implementation = _cosmo_cc_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c"]),
        "hdrs": attr.label_list(allow_files = [".h"]),
        "copts": attr.string_list(default = ["-O2"]),
        "_cosmocc": attr.label(
            default = "@cosmocc//:bin/cosmocc",
            allow_single_file = True,
            cfg = "exec",
        ),
        "_toolchain_files": attr.label(default = "@cosmocc//:all_files", cfg = "exec"),
    },
)
