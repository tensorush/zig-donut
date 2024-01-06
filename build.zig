const std = @import("std");

pub fn build(b: *std.Build) void {
    // Executable
    const exe_step = b.step("exe", "Run Donut animated ASCII art rendering");

    const exe = b.addExecutable(.{
        .name = "donut",
        .root_source_file = std.Build.LazyPath.relative("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);

    exe_step.dependOn(&exe_run.step);
    b.default_step.dependOn(exe_step);

    // Lints
    const lints_step = b.step("lint", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ "src", "build.zig" },
        .check = true,
    });

    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}
