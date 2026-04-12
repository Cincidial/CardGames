const Color = @import("engine").Color;
const sdlc = @import("engine").sdlc;
const Shader = @import("engine").Shader;
const Vec2 = @import("engine").Vec2;

pub var VertTexQuad = Shader.init("texQuad.vert") catch unreachable;
pub var VertTexInstQuad = Shader.init("texInstQuad.vert") catch unreachable;
pub var FragTexQuad = Shader.init("texQuad.frag") catch unreachable;

pub const VertInstQuadData = extern struct {
    tex_coord: Vec2,
    tex_dim: Vec2,
    pos: Vec2,
    scale: Vec2,
    color: Color,
};
