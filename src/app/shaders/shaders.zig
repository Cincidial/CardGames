const Color = @import("engine").Color;
const sdlc = @import("engine").sdlc;
const Shader = @import("engine").Shader;
const Vec2 = @import("engine").Vec2;
const Vec3 = @import("engine").Vec3;

pub var VertText = Shader.init("text.vert") catch unreachable;
pub var FragText = Shader.init("text.frag") catch unreachable;

pub const VertexTextData = extern struct {
    tex_coord: Vec2,
    tex_dim: Vec2,
    pos: Vec3,
    outline_size: f32 = 0,
    color: Color,
    outline_color: Color,
    scale: Vec2,
    padding2: Vec2 = Vec2.ZERO,
};
