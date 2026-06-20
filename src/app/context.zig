const std = @import("std");

const AudioDevice = @import("engine").AudioDevice;
const Font = @import("engine").typography.Font;
const sdl = @import("engine").sdl;
const sdlc = @import("engine").sdlc;
const Texture = @import("engine").Texture;
const Vec2 = @import("engine").Vec2;

const shaders = @import("shaders/shaders.zig");

const Text = @import("engine").Text.Text(shaders.VertInstQuadData);

pub const log = std.log.scoped(.App);
pub const window_dim = Vec2.init(720, 720);

pub var perm_arena: std.mem.Allocator = undefined;
pub var gpa: std.mem.Allocator = undefined;
pub var io: std.Io = undefined;
pub var prng: std.Random.DefaultPrng = undefined;

pub var window: *sdlc.SDL_Window = undefined;
pub var gpu_device: *sdlc.SDL_GPUDevice = undefined;
pub var audio_device: AudioDevice = undefined;
pub var sampler: *sdlc.SDL_GPUSampler = undefined;
pub var tex_quad_pipeline: *sdlc.SDL_GPUGraphicsPipeline = undefined;
pub var text_inst_quad_pipeline: *sdlc.SDL_GPUGraphicsPipeline = undefined;

pub var font: Font = undefined;
pub var font_text: Texture = undefined;
pub var text_renderer: Text.Renderer = undefined;
pub var title: Text = undefined;

// TODO: Thinking about to make the asset pipeline more string-hash-map data focused rather than creating variables
// What else can have a more data focused design as well?
//  - Strings
