const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 3) fatal("Calling requires at least 2 args", .{});

    const input_file_path = args[1];
    {
        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            std.debug.print("Converting input: {s}, to output: {s}\n", .{ input_file_path, args[i] });
            const result = try std.process.run(init.arena.allocator(), init.io, .{ .create_no_window = true, .argv = &[_][]const u8{ "shadercross", input_file_path, "-o", args[i] } });
            std.debug.print("{s}", .{result.stdout});
            switch (result.term) {
                .exited => |val| if (val != 0) fatal("Shaderscross failed, exit code: {d}, messages {s}", .{ val, result.stderr }),
                .signal => |sig| std.debug.print("Process was terminated by signal {d}\n", .{sig}),
                .stopped, .unknown => std.debug.print("Process was stopped or unkown", .{}),
            }
        }
    }
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
