const Color = @import("engine").Color;
const Rect = @import("engine").Rect;
const sdlc = @import("engine").sdlc;
const Vec2 = @import("engine").Vec2;

pub const TexVertex = extern struct {
    tex_coord: Vec2,
    pos: Vec2,

    pub fn init(tex_coord: Vec2, pos: Vec2) @This() {
        return .{ .tex_coord = tex_coord, .pos = pos };
    }

    /// Ordered as TL, BL, BR, TR
    pub fn fromRect(rect: *const Rect) [4]@This() {
        return .{
            init(Vec2.init(0, 0), Vec2.init(rect.left, rect.top)),
            init(Vec2.init(0, 1), Vec2.init(rect.left, rect.bottom)),
            init(Vec2.init(1, 1), Vec2.init(rect.right, rect.bottom)),
            init(Vec2.init(1, 0), Vec2.init(rect.right, rect.top)),
        };
    }

    pub fn vertexAttributes(buffer_slot: u32) [2]sdlc.SDL_GPUVertexAttribute {
        return .{
            Vec2.vertexAttribute(buffer_slot, 0, 0),
            Vec2.vertexAttribute(buffer_slot, 1, @sizeOf(Vec2)),
        };
    }
};
