const std = @import("std");

const sdl = @import("root.zig").sdl;
const sdlc = @import("root.zig").sdlc;
const Vec2 = @import("root.zig").Vec2;

pub const TextureError = error{
    CouldNotLoadPng,
    CouldNotCreateGpuTexture,
    CannotCreateTransferBuffer,
    CannotMapTransferBuffer,
    CouldNotAquireCmdBuffer,
    CommandSubmitFailed,
};
device: *sdlc.SDL_GPUDevice,
gpu_texture: *sdlc.SDL_GPUTexture,
dimensions: Vec2,

pub fn init(path: []const u8, device: *sdlc.SDL_GPUDevice) TextureError!@This() {
    const png = sdlc.SDL_LoadPNG(path.ptr) orelse return TextureError.CouldNotLoadPng;
    defer sdlc.SDL_DestroySurface(png);

    const png_argb_bytes: u32 = @intCast(png.*.w * png.*.h * sdl.SDL_BYTESPERPIXEL(png.*.format));
    const texture = sdlc.SDL_CreateGPUTexture(device, &sdlc.SDL_GPUTextureCreateInfo{
        .type = sdlc.SDL_GPU_TEXTURETYPE_2D,
        .format = sdlc.SDL_GetGPUTextureFormatFromPixelFormat(png.*.format),
        .width = @intCast(png.*.w),
        .height = @intCast(png.*.h),
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .usage = sdlc.SDL_GPU_TEXTUREUSAGE_SAMPLER,
    }) orelse return TextureError.CouldNotCreateGpuTexture;
    errdefer sdlc.SDL_ReleaseGPUTexture(device, texture);

    const transfer_buffer = sdlc.SDL_CreateGPUTransferBuffer(device, &sdlc.SDL_GPUTransferBufferCreateInfo{
        .usage = sdlc.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
        .size = png_argb_bytes,
    }) orelse return TextureError.CannotCreateTransferBuffer;
    defer sdlc.SDL_ReleaseGPUTransferBuffer(device, transfer_buffer);

    const transfer_data = sdlc.SDL_MapGPUTransferBuffer(device, transfer_buffer, false) orelse return TextureError.CannotMapTransferBuffer;
    _ = sdlc.SDL_memcpy(transfer_data, png.*.pixels, png_argb_bytes);
    sdlc.SDL_UnmapGPUTransferBuffer(device, transfer_buffer);

    const cmd_buf = sdlc.SDL_AcquireGPUCommandBuffer(device) orelse return TextureError.CouldNotAquireCmdBuffer;
    const copy_pass = sdlc.SDL_BeginGPUCopyPass(cmd_buf);
    {
        sdlc.SDL_UploadToGPUTexture(copy_pass, &sdlc.SDL_GPUTextureTransferInfo{
            .transfer_buffer = transfer_buffer,
            .offset = 0,
        }, &sdlc.SDL_GPUTextureRegion{
            .texture = texture,
            .w = @intCast(png.*.w),
            .h = @intCast(png.*.h),
            .d = 1,
        }, false);
    }
    sdlc.SDL_EndGPUCopyPass(copy_pass);
    if (!sdlc.SDL_SubmitGPUCommandBuffer(cmd_buf)) return TextureError.CommandSubmitFailed;

    return .{
        .device = device,
        .gpu_texture = texture,
        .dimensions = Vec2.init(@floatFromInt(png.*.w), @floatFromInt(png.*.h)),
    };
}

pub fn deinit(self: *@This()) void {
    sdlc.SDL_ReleaseGPUTexture(self.device, self.gpu_texture);
    self.* = undefined;
}
