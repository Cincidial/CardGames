const std = @import("std");

const sdlc = @import("root.zig").sdlc;

pub const Vec2 = extern struct {
    pub const ZERO: Vec2 = .{ .x = 0, .y = 0 };

    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn vertexAttribute(buffer_slot: u32, location_start: u32, offset: u32) sdlc.SDL_GPUVertexAttribute {
        return .{
            .location = location_start,
            .buffer_slot = buffer_slot,
            .format = sdlc.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,
            .offset = offset,
        };
    }

    /// Gets the ui coordinate based on a fraction of the window, with the top left being (0,0)
    pub fn fromUiRatio(window_dim: Vec2, x: f32, y: f32) Vec2 {
        return Vec2.init(((x * 2.0) - 1.0) * (window_dim.x / 2.0), (1.0 - (y * 2.0)) * (window_dim.y / 2.0));
    }

    pub inline fn negate(self: *const Vec2) Vec2 {
        return .init(-self.x, -self.y);
    }

    pub inline fn newX(vec2: Vec2, value: f32) Vec2 {
        return .{ .x = value, .y = vec2.y };
    }

    pub inline fn newY(vec2: Vec2, value: f32) Vec2 {
        return .{ .x = vec2.x, .y = value };
    }

    pub inline fn addX(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x + scalar, .y = vec2.y };
    }

    pub inline fn addY(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x, .y = vec2.y + scalar };
    }

    pub inline fn add(l: Vec2, r: Vec2) Vec2 {
        return .{ .x = l.x + r.x, .y = l.y + r.y };
    }

    pub inline fn subX(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x - scalar, .y = vec2.y };
    }

    pub inline fn subY(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x, .y = vec2.y - scalar };
    }

    pub inline fn sub(l: Vec2, r: Vec2) Vec2 {
        return .{ .x = l.x - r.x, .y = l.y - r.y };
    }

    pub inline fn multScalar(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x * scalar, .y = vec2.y * scalar };
    }

    pub inline fn div(l: Vec2, r: Vec2) Vec2 {
        return .{ .x = l.x / r.x, .y = l.y / r.y };
    }

    pub inline fn divScalar(vec2: Vec2, scalar: f32) Vec2 {
        return .{ .x = vec2.x / scalar, .y = vec2.y / scalar };
    }

    pub inline fn uniformBind(self: *const Vec2, cmd_buf: *sdlc.SDL_GPUCommandBuffer, slot_index: u32) void {
        sdlc.SDL_PushGPUVertexUniformData(cmd_buf, slot_index, @ptrCast(self), @sizeOf(@This()));
    }

    pub fn print(self: Vec2) void {
        std.debug.print("({d}, {d})\n", .{ self.x, self.y });
    }
};

pub const Vec3 = extern struct {
    pub const ZERO: Vec3 = .{ .x = 0, .y = 0, .z = 0 };

    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn vertexAttribute(buffer_slot: u32, location_start: u32, offset: u32) sdlc.SDL_GPUVertexAttribute {
        return .{
            .location = location_start,
            .buffer_slot = buffer_slot,
            .format = sdlc.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3,
            .offset = offset,
        };
    }

    pub inline fn negate(self: *const Vec3) Vec3 {
        return .init(-self.x, -self.y, -self.z);
    }

    pub inline fn newX(vec3: Vec3, value: f32) Vec3 {
        return .{ .x = value, .y = vec3.y, .z = vec3.z };
    }

    pub inline fn newY(vec3: Vec3, value: f32) Vec3 {
        return .{ .x = vec3.x, .y = value, .z = vec3.z };
    }

    pub inline fn addX(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x + scalar, .y = vec3.y, .z = vec3.z };
    }

    pub inline fn addY(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x, .y = vec3.y + scalar, .z = vec3.z };
    }

    pub inline fn addVec2(l: Vec3, r: Vec2) Vec3 {
        return .{ .x = l.x + r.x, .y = l.y + r.y, .z = l.z };
    }

    pub inline fn add(l: Vec3, r: Vec3) Vec3 {
        return .{ .x = l.x + r.x, .y = l.y + r.y, .z = l.z + r.z };
    }

    pub inline fn subX(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x - scalar, .y = vec3.y, .z = vec3.z };
    }

    pub inline fn subY(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x, .y = vec3.y - scalar, .z = vec3.z };
    }

    pub inline fn subVec2(l: Vec3, r: Vec2) Vec3 {
        return .{ .x = l.x - r.x, .y = l.y - r.y, .z = l.z };
    }

    pub inline fn sub(l: Vec3, r: Vec3) Vec3 {
        return .{ .x = l.x - r.x, .y = l.y - r.y, .z = l.z - r.z };
    }

    pub inline fn multScalar(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x * scalar, .y = vec3.y * scalar, .z = vec3.z * scalar };
    }

    pub inline fn div(l: Vec3, r: Vec3) Vec3 {
        return .{ .x = l.x / r.x, .y = l.y / r.y, .z = l.z / r.z };
    }

    pub inline fn divScalar(vec3: Vec3, scalar: f32) Vec3 {
        return .{ .x = vec3.x / scalar, .y = vec3.y / scalar, .z = vec3.z / scalar };
    }

    pub inline fn uniformBind(self: *const Vec3, cmd_buf: *sdlc.SDL_GPUCommandBuffer, slot_index: u32) void {
        sdlc.SDL_PushGPUVertexUniformData(cmd_buf, slot_index, @ptrCast(self), @sizeOf(@This()));
    }

    pub fn print(self: Vec3) void {
        std.debug.print("({d}, {d}, {d})\n", .{ self.x, self.y, self.z });
    }
};

/// SDL GPU API is Col-Major
/// Default values are the identity matrix
pub const Mat4 = extern struct {
    pub const IDENTITY: Mat4 = .{};

    r1c1: f32 = 1, // Scale x
    r2c1: f32 = 0,
    r3c1: f32 = 0, // Trans x
    r4c1: f32 = 0,

    r1c2: f32 = 0,
    r2c2: f32 = 1, // Scale y
    r3c2: f32 = 0, // Trans y
    r4c2: f32 = 0,

    r1c3: f32 = 0,
    r2c3: f32 = 0,
    r3c3: f32 = 1, // Scale z
    r4c3: f32 = 0, // Trans z

    r1c4: f32 = 0,
    r2c4: f32 = 0,
    r3c4: f32 = 0,
    r4c4: f32 = 1,

    pub fn orthographic(r: f32, l: f32, t: f32, b: f32) Mat4 {
        const r_minus_l = r - l;
        const r_plus_l = r + l;

        const t_minus_b = t - b;
        const t_plus_b = t + b;

        return .{
            .r1c1 = 2.0 / r_minus_l,
            .r3c1 = -(r_plus_l / r_minus_l),
            .r2c2 = 2.0 / t_minus_b,
            .r3c2 = -(t_plus_b / t_minus_b),
        };
    }

    pub inline fn uniformBind(self: *const Mat4, cmd_buf: *sdlc.SDL_GPUCommandBuffer, slot_index: u32) void {
        sdlc.SDL_PushGPUVertexUniformData(cmd_buf, slot_index, @ptrCast(self), @sizeOf(@This()));
    }

    pub fn print(self: Mat4) void {
        std.debug.print("({d}, {d}, {d})\n{d}, {d}, {d})\n{d}, {d}, {d})\n", .{
            self.r1c1,
            self.r1c2,
            self.r1c3,
            self.r2c1,
            self.r2c2,
            self.r2c3,
            self.r3c1,
            self.r3c2,
            self.r3c3,
        });
    }
};
