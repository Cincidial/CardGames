const Color = @import("engine").Color;
const sdlc = @import("engine").sdlc;
const Shader = @import("engine").Shader;
const Vec2 = @import("engine").Vec2;
const Vec3 = @import("engine").Vec3;

pub var VertTexQuad = Shader.init("texQuad.vert") catch unreachable;
pub var VertTexInstQuad = Shader.init("texInstQuad.vert") catch unreachable;
pub var FragTexQuad = Shader.init("texQuad.frag") catch unreachable;

pub const VertInstQuadData = extern struct {
    tex_coord: Vec2,
    tex_dim: Vec2,
    pos: Vec3,
    padding: f32 = 0,
    color: Color,
    scale: Vec2,
    padding2: Vec2 = Vec2.ZERO,
};
