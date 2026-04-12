const std = @import("std");

const sdlc = @import("root.zig").sdlc;

const ShaderError = error{
    UnableToDetermineShaderStage,
    DeviceShaderFormatNotSupported,
    UnableToCreateShader,
};

spv: [:0]const u8,
msl: [:0]const u8,
dxil: [:0]const u8,
stage: sdlc.SDL_GPUShaderStage,

pub fn init(comptime name: []const u8) ShaderError!@This() {
    return .{
        .spv = @embedFile(name ++ ".spv"),
        .msl = @embedFile(name ++ ".msl"),
        .dxil = @embedFile(name ++ ".dxil"),
        .stage = if (std.mem.endsWith(u8, name, "vert")) sdlc.SDL_GPU_SHADERSTAGE_VERTEX else if (std.mem.endsWith(u8, name, "frag")) sdlc.SDL_GPU_SHADERSTAGE_FRAGMENT else return ShaderError.UnableToDetermineShaderStage,
    };
}

pub fn createShader(self: *@This(), device: ?*sdlc.SDL_GPUDevice, samplers: u32, uniform_bufs: u32, storage_bufs: u32, storage_textures: u32) ShaderError!*sdlc.SDL_GPUShader {
    const formats = sdlc.SDL_GetGPUShaderFormats(device);

    var file: [:0]const u8 = undefined;
    var format: sdlc.SDL_GPUShaderFormat = sdlc.SDL_GPU_SHADERFORMAT_INVALID;
    var entry_point: [:0]const u8 = undefined;
    if ((formats & sdlc.SDL_GPU_SHADERFORMAT_SPIRV) != 0) {
        file = self.spv;
        format = sdlc.SDL_GPU_SHADERFORMAT_SPIRV;
        entry_point = "main";
    } else if ((formats & sdlc.SDL_GPU_SHADERFORMAT_MSL) != 0) {
        file = self.msl;
        format = sdlc.SDL_GPU_SHADERFORMAT_MSL;
        entry_point = "main0";
    } else if ((formats & sdlc.SDL_GPU_SHADERFORMAT_DXIL) != 0) {
        file = self.dxil;
        format = sdlc.SDL_GPU_SHADERFORMAT_DXIL;
        entry_point = "main";
    } else {
        return ShaderError.UnableToDetermineShaderStage;
    }

    return sdlc.SDL_CreateGPUShader(device, &sdlc.SDL_GPUShaderCreateInfo{
        .code_size = file.len,
        .code = file.ptr,
        .entrypoint = entry_point,
        .format = format,
        .stage = self.stage,
        .num_samplers = samplers,
        .num_uniform_buffers = uniform_bufs,
        .num_storage_buffers = storage_bufs,
        .num_storage_textures = storage_textures,
    }) orelse return ShaderError.UnableToCreateShader;
}
