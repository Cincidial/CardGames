const std = @import("std");

const app_name = "CardGames";
const asset_dir_name = "assets";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add the engine lib
    const engine_mod = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Asset gen step
    const assetgen = b.addExecutable(.{
        .name = "assetgen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/assetgen.zig"),
            .target = b.graph.host,
        }),
    });
    const assetgen_step = b.step("assetgen", "Generate zig code for assets");
    const assetgen_cmd = b.addRunArtifact(assetgen);
    assetgen_step.dependOn(&assetgen_cmd.step);
    assetgen_cmd.addDirectoryArg(b.path(asset_dir_name));
    const assetgen_file = assetgen_cmd.addOutputFileArg("assets.zig");
    const assetgen_mod = b.createModule(.{
        .root_source_file = assetgen_file,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "engine", .module = engine_mod },
        },
    });

    // Create the exe
    const exe = b.addExecutable(.{
        .name = app_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/app/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "engine", .module = engine_mod },
                .{ .name = "assets", .module = assetgen_mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Add asset files to the output
    const assets = b.addInstallDirectory(.{
        .source_dir = b.path(asset_dir_name),
        .install_dir = .{ .prefix = {} },
        .install_subdir = asset_dir_name,
    });
    b.getInstallStep().dependOn(&assets.step);

    // Add SDL
    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl_lib = sdl_dep.artifact("SDL3");
    engine_mod.linkLibrary(sdl_lib);
    exe.root_module.linkLibrary(sdl_lib);

    // Add shaders
    const shadercross = b.addExecutable(.{
        .name = "shadercross",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/shadercross.zig"),
            .target = b.graph.host,
        }),
    });
    try addShadercrossFile(b, shadercross, engine_mod, "texQuad.vert");
    try addShadercrossFile(b, shadercross, engine_mod, "texInstQuad.vert");
    try addShadercrossFile(b, shadercross, engine_mod, "texQuad.frag");

    // Run step
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Testing
    const mod_tests = b.addTest(.{ .root_module = engine_mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    // This section is for ZLS to compile on save
    const exe_check = b.addExecutable(.{
        .name = "CompileCheck",
        .root_module = exe.root_module,
    });
    const check = b.step("check", "Check compilation");
    check.dependOn(&exe_check.step);
}

fn addShadercrossFile(b: *std.Build, shadercross: *std.Build.Step.Compile, lib: *std.Build.Module, shader: []const u8) !void {
    var buffer = [_]u8{undefined} ** 256;

    const shader_path = try std.fmt.bufPrint(&buffer, "src/app/shaders/{s}.hlsl", .{shader});
    const shader_step = b.addRunArtifact(shadercross);
    shader_step.addFileArg(b.path(shader_path));

    const output_extensions: [3][]const u8 = .{ "spv", "dxil", "msl" };
    for (output_extensions) |ext| {
        const output_name = try std.fmt.bufPrint(&buffer, "{s}.{s}", .{ shader, ext });
        const output_file = shader_step.addOutputFileArg(output_name);
        lib.addAnonymousImport(output_name, .{ .root_source_file = output_file });
    }
}
