const std = @import("std");

const Vec2 = @import("root.zig").Vec2;

/// This is an axis-aligned rectangle
pub const Rect = struct {
    left: f32,
    top: f32,
    right: f32,
    bottom: f32,
    width: f32,
    height: f32,
    middle: Vec2,

    pub fn init(left: f32, top: f32, right: f32, bottom: f32) Rect {
        return .{
            .left = left,
            .top = top,
            .right = right,
            .bottom = bottom,
            .width = right - left,
            .height = top - bottom,
            .middle = Vec2.init((left + right) / 2.0, (top + bottom / 2.0)),
        };
    }

    pub fn initVec(top_left: Vec2, bottom_right: Vec2) Rect {
        return init(top_left.x, top_left.y, bottom_right.x, bottom_right.y);
    }

    pub fn initCentered(center: Vec2, dimensions: Vec2) Rect {
        return initVec(center.add(dimensions.div(Vec2.init(-2, 2))), center.add(dimensions.div(Vec2.init(2, -2))));
    }

    pub inline fn topLeft(self: *const Rect) Vec2 {
        return .init(self.left, self.top);
    }

    pub fn translate(self: *const Rect, translation: Vec2) Rect {
        return .{
            .left = self.left + translation.x,
            .top = self.top + translation.y,
            .right = self.right + translation.x,
            .bottom = self.bottom + translation.y,
            .width = self.width,
            .height = self.height,
            .middle = self.middle.add(translation),
        };
    }

    pub fn containsPoint(self: *const Rect, point: Vec2) bool {
        return (self.left <= point.x) and (self.right >= point.x) and (self.top >= point.y) and (self.bottom <= point.y);
    }

    pub fn print(self: *const Rect) void {
        std.debug.print("(left: {d}, top: {d}, right: {d}, bottom: {d})\n", .{ self.left, self.top, self.right, self.bottom });
    }
};
