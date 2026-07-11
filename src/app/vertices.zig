const Color = @import("engine").Color;
const Rect = @import("engine").Rect;
const sdlc = @import("engine").sdlc;
const Vec2 = @import("engine").Vec2;
const Vec3 = @import("engine").Vec3;

pub const TexVertex = extern struct {
    tex_coord: Vec2,
    pos: Vec3, // Z-axis is used for depth

    pub fn init(tex_coord: Vec2, pos: Vec3) @This() {
        return .{ .tex_coord = tex_coord, .pos = pos };
    }

    pub fn vertexAttributes(buffer_slot: u32) [2]sdlc.SDL_GPUVertexAttribute {
        return .{
            Vec2.vertexAttribute(buffer_slot, 0, 0),
            Vec3.vertexAttribute(buffer_slot, 1, @sizeOf(Vec2)),
        };
    }
};
