const std = @import("std");

const sdlc = @import("root.zig").sdlc;

pub const Color = extern struct {
    pub const TRANSPARENT: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 0.0 };
    pub const WHITE: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
    pub const BLACK: Color = .{ .r = 0, .g = 0, .b = 0, .a = 1.0 };
    pub const RED: Color = .{ .r = 1.0, .g = 0, .b = 0, .a = 1.0 };
    pub const YELLOW: Color = .{ .r = 0.25, .g = 1.0, .b = 0.5, .a = 1.0 };
    pub const GREEN: Color = .{ .r = 0, .g = 1.0, .b = 0, .a = 1.0 };

    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) @This() {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn initHex(string: []const u8) !@This() {
        std.debug.assert(string.len == 8);

        var bytes: [4]u8 = undefined;
        const decoded = try std.fmt.hexToBytes(&bytes, string);

        return .init(
            @as(f32, @floatFromInt(decoded[0])) / 255,
            @as(f32, @floatFromInt(decoded[1])) / 255,
            @as(f32, @floatFromInt(decoded[2])) / 255,
            @as(f32, @floatFromInt(decoded[3])) / 255,
        );
    }

    pub fn vertexAttribute(buffer_slot: u32, location_start: u32, offset: u32) sdlc.SDL_GPUVertexAttribute {
        return .{
            .location = location_start,
            .buffer_slot = buffer_slot,
            .format = sdlc.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,
            .offset = offset,
        };
    }
};
