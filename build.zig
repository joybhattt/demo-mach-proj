const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // 1. Fetch all your dependency packages defined in your build.zig.zon manifest
    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
        
        .sysgpu = true,
        .sysaudio = true,
        .core = true,
    });

    const zigimg_dep = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    const options = b.addOptions();
    options.addOption(bool, "debug_todo", true);
    const ttf_dep = b.dependency("truetype", .{});
    const ttf_mod = b.createModule(.{
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{ .name = "build_options", .module = options.createModule() },
        },
        .root_source_file = ttf_dep.path("TrueType.zig"),
    });

    const flac_dep = b.dependency("flac", .{
        .target = target,
        .optimize = optimize,
    });

    const wav_dep = b.dependency("wav", .{
        .target = target,
        .optimize = optimize,
    });

    // 2. Build the main application executable artifact
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mach", .module = mach_dep.module("mach") },
                .{ .name = "zigimg", .module = zigimg_dep.module("zigimg") },
                .{ .name = "flac", .module = flac_dep.module("flac") },
                .{ .name = "wav", .module = wav_dep.module("wav") },
                .{ .name = "TrueType", .module = ttf_mod },
            },
        }),
    });

    // 3. Make sure the executable artifacts are generated and output to zig-out/bin/
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
