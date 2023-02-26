const std = @import("std");
const builtin = @import("builtin");
const sokol_build = @import("vendor/sokol-zig/build.zig");
const build_util = @import("build_util.zig");

const UnmanagedDeps = struct {
    pub usingnamespace build_util.BuildDepsMixin(@This());

    pub const sokol = build_util.BuildDependency{
        .pkg = std.Build.CreateModuleOptions{
            .source_file = .{ .path = "vendor/sokol-zig/src/sokol/sokol.zig" },
            .dependencies = &[_]std.Build.ModuleDependency{},
        },
        .buildFn = &(struct {
            pub fn sokolBuild(b: *std.build.Builder, exe: *std.build.LibExeObjStep) void {
                const sokol_cfg = sokol_build.SokolBuildOpts{
                    .backend = .d3d11,
                    .zig_assert_hook = true,
                    .zig_log_hook = true,
                };
                const sokol_artifact = sokol_build.buildSokol(b, exe.target, exe.optimize, sokol_cfg, "vendor/sokol-zig/");
                exe.linkLibrary(sokol_artifact);
            }
        }).sokolBuild,

        .test_src = .none,
    };
};

pub fn build(b: *std.Build) void {
    std.log.info("Zig version: {}", .{builtin.zig_version});

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const main_src_root = "libs/main/src/main.zig";
    const exe = b.addExecutable(.{
        .name = "zig-bugs",
        .root_source_file = .{ .path = main_src_root },
        .target = target,
        .optimize = optimize,
    });

    var output_dir_buf = [_]u8{0} ** 20;
    exe.setOutputDir(std.fmt.bufPrint(&output_dir_buf, "build/{s}", .{@tagName(optimize)}) catch unreachable);
    exe.install();

    UnmanagedDeps.buildAndAddAllPkgs(b, exe);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
