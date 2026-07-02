const std = @import("std");

const AudioDevice = @import("root.zig").AudioDevice;
const AudioStream = @import("root.zig").AudioStream;
const Font = @import("root.zig").typography.Font;
const sdl = @import("root.zig").sdl;
const sdlc = @import("root.zig").sdlc;
const Texture = @import("root.zig").Texture;

io: std.Io,
allocator: std.mem.Allocator,
gpu_device: *sdlc.SDL_GPUDevice,
audio_device: *const AudioDevice,
fonts: std.StringHashMap(Font),
sounds: std.StringHashMap(AudioStream),
textures: std.StringHashMap(Texture),

pub fn init(io: std.Io, allocator: std.mem.Allocator, gpu_device: *sdlc.SDL_GPUDevice, audio_device: *const AudioDevice) @This() {
    return .{
        .io = io,
        .allocator = allocator,
        .gpu_device = gpu_device,
        .audio_device = audio_device,
        .fonts = .init(allocator),
        .sounds = .init(allocator),
        .textures = .init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    var font_iter = self.fonts.valueIterator();
    while (font_iter.next()) |value| value.deinit();
    self.fonts.deinit();

    var sound_iter = self.sounds.valueIterator();
    while (sound_iter.next()) |value| value.deinit();
    self.sounds.deinit();

    var prite_iter = self.textures.valueIterator();
    while (prite_iter.next()) |value| value.deinit();
    self.textures.deinit();

    self.* = undefined;
}

/// This function assumes that "name" is located at the path "../assets/fonts/name"
pub fn getFont(self: *@This(), name: []const u8) !*Font {
    const path = try std.fs.path.joinZ(self.allocator, &.{ sdl.SDL_GetBasePath(), "..", "assets", "fonts", name });
    defer self.allocator.free(path);

    const entry = try self.fonts.getOrPutValue(name, try Font.init(self.io, path));
    return entry.value_ptr;
}

/// This function assumes that "name" is located at the path "../assets/audio/name"
pub fn getSound(self: *@This(), name: []const u8) !*AudioStream {
    const path = try std.fs.path.joinZ(self.allocator, &.{ sdl.SDL_GetBasePath(), "..", "assets", "audio", name });
    defer self.allocator.free(path);

    const entry = try self.sounds.getOrPutValue(name, try AudioStream.init(path, self.audio_device));
    return entry.value_ptr;
}

/// This function assumes that "name" is located at the path "../assets/sprites/name"
pub fn getTexture(self: *@This(), name: []const u8) !*Texture {
    const path = try std.fs.path.joinZ(self.allocator, &.{ sdl.SDL_GetBasePath(), "..", "assets", "sprites", name });
    defer self.allocator.free(path);

    const entry = try self.textures.getOrPutValue(name, try Texture.init(path, self.gpu_device));
    return entry.value_ptr;
}
