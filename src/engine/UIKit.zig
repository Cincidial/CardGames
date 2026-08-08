const Mat4 = @import("root.zig").Mat4;
const Rect = @import("root.zig").Rect;
const sdlc = @import("root.zig").sdlc;
const Vec2 = @import("root.zig").Vec2;
const Text = @import("root.zig").Text;
const Color = @import("root.zig").Color;

pub const Data = struct {
    has_gpu_upload_changes: bool = false,
    has_mouse_entered: bool = false,
    bounds: Rect,
    on_mouse_enter: ?Lambdas.MouseMotionChangeOutlineColor = undefined,
    on_mouse_exit: ?Lambdas.MouseMotionChangeOutlineColor = undefined,
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
                if (!impl.ui_kit.has_gpu_upload_changes) return;
                try impl.copyPass(copy_pass);
                impl.ui_kit.has_gpu_upload_changes = false;
            },
        }
    }

    // TODO: Better handling of uniforms, instead of just taking in a required Mat4
    pub fn renderPass(self: *@This(), cmd_buf: *sdlc.SDL_GPUCommandBuffer, render_pass: *sdlc.SDL_GPURenderPass, projection: Mat4) void {
        switch (self.*) {
            inline else => |*impl| impl.renderPass(cmd_buf, render_pass, projection),
        }
    }

    pub fn mouseMotion(self: *@This(), mouse: Vec2) !void {
        switch (self.*) {
            inline else => |*impl| {
                if (impl.ui_kit.bounds.containsPoint(mouse)) {
                    if (!impl.ui_kit.has_mouse_entered) {
                        impl.ui_kit.has_mouse_entered = true;
                        if (impl.ui_kit.on_mouse_enter) |*lamda| try lamda.call(self);
                    }
                } else if (impl.ui_kit.has_mouse_entered) {
                    impl.ui_kit.has_mouse_entered = false;
                    if (impl.ui_kit.on_mouse_exit) |*lamda| try lamda.call(self);
                }
            },
        }
    }
};

pub fn Lambda(comptime T: type, comptime func: *const fn (impl: *Interface, context: T) anyerror!void) type {
    return struct {
        context: T,
        func: *const fn (obj: *Interface, context: T) anyerror!void = func,

        pub fn call(self: *@This(), obj: *Interface) anyerror!void {
            try self.func(obj, self.context);
        }
    };
}
pub const Lambdas = struct {
    const MouseMotionChangeOutlineColorContext = struct { color: Color };
    fn mouseMotionChangeOutlineColor(obj: *Interface, context: MouseMotionChangeOutlineColorContext) !void {
        switch (obj.*) {
            .text => |*impl| {
                impl.changeOutlineColor(context.color);
            },
        }
    }
    pub const MouseMotionChangeOutlineColor = Lambda(MouseMotionChangeOutlineColorContext, mouseMotionChangeOutlineColor);
};

/// Gets the ui coordinate based on a fraction of the window, with the top left being (0,0)
pub fn vec2FromUiRatio(window_dim: Vec2, x: f32, y: f32) Vec2 {
    return Vec2.init(((x * 2.0) - 1.0) * (window_dim.x / 2.0), (1.0 - (y * 2.0)) * (window_dim.y / 2.0));
}

pub fn vec2FromMouse(window_dim: Vec2, x: f32, y: f32) Vec2 {
    return Vec2.init(x - window_dim.x / 2.0, y - window_dim.y / 2.0);
}
