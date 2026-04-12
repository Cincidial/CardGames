const std = @import("std");

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    if (args.len != 3) fatal("Calling requires 2 args (asset folder path, output file path)", .{});

    const folder_path = args[1];
    var folder = try std.fs.openDirAbsolute(folder_path, .{ .iterate = true });
    defer folder.close();

    var walker = try folder.walk(arena);
    defer walker.deinit();

    const file_path = args[2];
    const file = try std.fs.createFileAbsolute(file_path, .{});

    const base_asset_bin_path = try std.fs.path.join(arena, &.{ "..", "assets" });
    var texture_strings = try std.ArrayList([]const u8).initCapacity(arena, 100);
    var audio_strings = try std.ArrayList([]const u8).initCapacity(arena, 100);
    var font_strings = try std.ArrayList([]const u8).initCapacity(arena, 100);
    var init_strings = try std.ArrayList([]const u8).initCapacity(arena, 100);
    var deinit_strings = try std.ArrayList([]const u8).initCapacity(arena, 100);
    const template =
        \\const std = @import("std");
        \\const sdl = @import("engine").sdl;
        \\const sdlc = @import("engine").sdlc;
        \\const AudioDevice = @import("engine").AudioDevice;
        \\const AudioStream = @import("engine").AudioStream;
        \\const Texture = @import("engine").Texture;
        \\const typography = @import("engine").typography;
        \\
        \\pub const Audio = struct {{
        \\{s}
        \\}};
        \\
        \\pub const Fonts = struct {{
        \\{s}
        \\}};
        \\
        \\pub const Textures = struct {{
        \\{s}
        \\}};
        \\
        \\var finished_init = false;
        \\pub fn init(gpu_device: *sdlc.SDL_GPUDevice, audio_device: *AudioDevice) !void {{
        \\    var buffer: [std.fs.max_path_bytes]u8 = undefined;
        \\    var path_alloc: std.heap.FixedBufferAllocator = .init(&buffer);
        \\    var path: [:0]u8 = undefined;
        \\{s}
        \\
        \\    finished_init = true;
        \\}}
        \\
        \\pub fn deinit() void {{
        \\    if (!finished_init) return;
        \\
        \\{s}
        \\
        \\    finished_init = false;
        \\}}
    ;

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const ext = std.fs.path.extension(entry.path);
            const name = entry.basename[0 .. entry.basename.len - ext.len];

            const init_path_string = try std.fmt.allocPrint(
                arena,
                "\n    path = try std.fs.path.joinZ(path_alloc.allocator(), &.{{ sdl.SDL_GetBasePath(), \"{s}\", \"{s}\" }});",
                .{ base_asset_bin_path, entry.path },
            );
            const init_free_string = "    path_alloc.allocator().free(path);";

            if (std.mem.eql(u8, ext, ".png")) {
                const name_string = try std.fmt.allocPrint(arena, "    pub var {s}: Texture = undefined;", .{name});
                const init_set_var_string = try std.fmt.allocPrint(arena, "    Textures.{s} = try .init(path, gpu_device);", .{name});
                const init_errdefer_string = try std.fmt.allocPrint(arena, "    errdefer Textures.{s}.deinit();", .{name});
                const deinit_string = try std.fmt.allocPrint(arena, "    Textures.{s}.deinit();", .{name});

                try texture_strings.append(arena, name_string);
                try init_strings.append(arena, init_path_string);
                try init_strings.append(arena, init_set_var_string);
                try init_strings.append(arena, init_errdefer_string);
                try init_strings.append(arena, init_free_string);
                try deinit_strings.append(arena, deinit_string);
            } else if (std.mem.eql(u8, ext, ".wav")) {
                const name_string = try std.fmt.allocPrint(arena, "    pub var {s}: AudioStream = undefined;", .{name});
                const init_set_var_string = try std.fmt.allocPrint(arena, "    Audio.{s} = try .init(path, audio_device);", .{name});
                const init_errdefer_string = try std.fmt.allocPrint(arena, "    errdefer Audio.{s}.deinit();", .{name});
                const deinit_string = try std.fmt.allocPrint(arena, "    Audio.{s}.deinit();", .{name});

                try audio_strings.append(arena, name_string);
                try init_strings.append(arena, init_path_string);
                try init_strings.append(arena, init_set_var_string);
                try init_strings.append(arena, init_errdefer_string);
                try init_strings.append(arena, init_free_string);
                try deinit_strings.append(arena, deinit_string);
            } else if (std.mem.eql(u8, ext, ".fnt")) {
                const name_string = try std.fmt.allocPrint(arena, "    pub var {s}: typography.Font = undefined;", .{name});
                const init_set_var_string = try std.fmt.allocPrint(arena, "    Fonts.{s} = try .init(path);", .{name});

                try font_strings.append(arena, name_string);
                try init_strings.append(arena, init_path_string);
                try init_strings.append(arena, init_set_var_string);
                try init_strings.append(arena, init_free_string);
            }
        }
    }

    const texture_string = try std.mem.join(arena, "\n", texture_strings.items);
    const audio_string = try std.mem.join(arena, "\n", audio_strings.items);
    const font_string = try std.mem.join(arena, "\n", font_strings.items);
    const init_string = try std.mem.join(arena, "\n", init_strings.items);
    const deinit_string = try std.mem.join(arena, "\n", deinit_strings.items);
    const file_data = try std.fmt.allocPrint(arena, template, .{ audio_string, font_string, texture_string, init_string, deinit_string });
    _ = try file.write(file_data);
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
