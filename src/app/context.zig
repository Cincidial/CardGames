const std = @import("std");

const AudioDevice = @import("engine").AudioDevice;
const Mat4 = @import("engine").Mat4;
const ResourceManager = @import("engine").ResourceManager;
const sdl = @import("engine").sdl;
const sdlc = @import("engine").sdlc;
const TextRenderContext = @import("engine").Text.TextRenderContext;
const Vec2 = @import("engine").Vec2;
const UIKit = @import("engine").UIKit;

const shaders = @import("shaders/shaders.zig");

const Text = @import("engine").Text.Text(shaders.VertexTextData);

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
pub var text_pipeline: *sdlc.SDL_GPUGraphicsPipeline = undefined;

pub var resource_manager: ResourceManager = undefined;
pub var text_render_context: TextRenderContext = undefined;
pub var ui: std.ArrayList(UIKit.Interface) = .empty;
pub var projection: Mat4 = undefined;
