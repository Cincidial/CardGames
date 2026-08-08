const Color = @import("engine").Color;
const sdlc = @import("engine").sdlc;
const Shader = @import("engine").Shader;
const Vec2 = @import("engine").Vec2;
const Vec3 = @import("engine").Vec3;

pub var VertText = Shader.init("text.vert") catch unreachable;
pub var FragText = Shader.init("text.frag") catch unreachable;
