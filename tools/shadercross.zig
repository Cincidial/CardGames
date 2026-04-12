const std = @import("std");

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);
    if (args.len < 3) fatal("Calling requires at least 2 args", .{});

    const input_file_path = args[1];
    {
        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            std.debug.print("Converting input: {s}, to output: {s}\n", .{ input_file_path, args[i] });
            var child = std.process.Child.init(&[_][]const u8{ "shadercross", input_file_path, "-o", args[i] }, arena);
            const exit_code = try child.spawnAndWait();
            if (exit_code.Exited != 0) fatal("Bad run of shaderscross, exit code: {d}", .{exit_code.Exited});
        }
    }
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
