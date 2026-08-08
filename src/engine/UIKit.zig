const Mat4 = @import("root.zig").Mat4;
const Rect = @import("root.zig").Rect;
const sdlc = @import("root.zig").sdlc;
const Vec2 = @import("root.zig").Vec2;
const Text = @import("root.zig").Text;

pub const Data = struct {
    has_changes: bool = false,
    bounds: Rect,
    on_mouse_enter_fn: ?*const fn (mouse: Vec2) anyerror!void = undefined,
    on_mouse_leave_fn: ?*const fn (mouse: Vec2) anyerror!void = undefined,
};

pub const Interface = union(enum) {
    text: Text,

    pub fn deinit(self: *@This()) void {
        switch (self.*) {
            inline else => |*impl| impl.deinit(),
        }
    }

    pub fn copyPass(self: *@This(), copy_pass: *sdlc.SDL_GPUCopyPass) !void {
        switch (self.*) {
            inline else => |*impl| {
                if (!impl.ui_kit.has_changes) return;
                try impl.copyPass(copy_pass);
                impl.ui_kit.has_changes = false;
            },
        }
    }

    // TODO: Better handling of uniforms, instead of just taking in a required Mat4
    pub fn renderPass(self: *@This(), cmd_buf: *sdlc.SDL_GPUCommandBuffer, render_pass: *sdlc.SDL_GPURenderPass, projection: Mat4) void {
        switch (self.*) {
            inline else => |*impl| impl.renderPass(cmd_buf, render_pass, projection),
        }
    }

    pub fn mouseMovement(self: *@This(), mouse: Vec2) void {
        switch (self.*) {
            inline else => |*impl| {
                if (impl.ui_kit.bounds.containsPoint(mouse)) {}
            },
        }
    }
};

/// Gets the ui coordinate based on a fraction of the window, with the top left being (0,0)
pub fn vec2FromUiRatio(window_dim: Vec2, x: f32, y: f32) Vec2 {
    return Vec2.init(((x * 2.0) - 1.0) * (window_dim.x / 2.0), (1.0 - (y * 2.0)) * (window_dim.y / 2.0));
}
