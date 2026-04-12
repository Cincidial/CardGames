const std = @import("std");

const sdlc = @import("root.zig").sdlc;

const VertexBufferError = error{
    CannotCreateVertexBuffer,
    CannotCreateIndexBuffer,
    CannotCreateTransferBuffer,
    CannotMapTransferBuffer,
    CouldNotGetCommandBuffer,
    CopyCommandSubmitFailed,
};
device: *sdlc.SDL_GPUDevice,
num_indices: u32,
vert_buf: *sdlc.SDL_GPUBuffer,
idx_buf: *sdlc.SDL_GPUBuffer,

/// Where T is the vertex struct type
pub fn init(comptime T: type, device: *sdlc.SDL_GPUDevice, data: []const T, indices: []const u16) VertexBufferError!@This() {
    const vert_size: u32 = @intCast(@sizeOf(T) * data.len);
    const vert_buffer = sdlc.SDL_CreateGPUBuffer(device, &sdlc.SDL_GPUBufferCreateInfo{
        .usage = sdlc.SDL_GPU_BUFFERUSAGE_VERTEX,
        .size = vert_size,
    }) orelse return VertexBufferError.CannotCreateVertexBuffer;
    errdefer sdlc.SDL_ReleaseGPUBuffer(device, vert_buffer);

    const idx_size: u32 = @intCast(@sizeOf(u16) * indices.len);
    const idx_buffer = sdlc.SDL_CreateGPUBuffer(device, &sdlc.SDL_GPUBufferCreateInfo{
        .usage = sdlc.SDL_GPU_BUFFERUSAGE_INDEX,
        .size = idx_size,
    }) orelse return VertexBufferError.CannotCreateIndexBuffer;
    errdefer sdlc.SDL_ReleaseGPUBuffer(device, idx_buffer);

    const transfer_buffer = sdlc.SDL_CreateGPUTransferBuffer(device, &sdlc.SDL_GPUTransferBufferCreateInfo{
        .usage = sdlc.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
        .size = vert_size + idx_size,
    }) orelse return VertexBufferError.CannotCreateTransferBuffer;
    defer sdlc.SDL_ReleaseGPUTransferBuffer(device, transfer_buffer);

    const transfer_data = sdlc.SDL_MapGPUTransferBuffer(device, transfer_buffer, false) orelse return VertexBufferError.CannotMapTransferBuffer;
    _ = sdlc.SDL_memcpy(transfer_data, data.ptr, vert_size);
    _ = sdlc.SDL_memcpy(@ptrFromInt(@intFromPtr(transfer_data) + vert_size), indices.ptr, idx_size);
    sdlc.SDL_UnmapGPUTransferBuffer(device, transfer_buffer);

    const upload_cmd_buffer = sdlc.SDL_AcquireGPUCommandBuffer(device) orelse return VertexBufferError.CouldNotGetCommandBuffer;
    const copy_pass = sdlc.SDL_BeginGPUCopyPass(upload_cmd_buffer);
    {
        sdlc.SDL_UploadToGPUBuffer(copy_pass, &sdlc.SDL_GPUTransferBufferLocation{
            .transfer_buffer = transfer_buffer,
            .offset = 0,
        }, &sdlc.SDL_GPUBufferRegion{
            .buffer = vert_buffer,
            .offset = 0,
            .size = vert_size,
        }, false);
        sdlc.SDL_UploadToGPUBuffer(copy_pass, &sdlc.SDL_GPUTransferBufferLocation{
            .transfer_buffer = transfer_buffer,
            .offset = vert_size,
        }, &sdlc.SDL_GPUBufferRegion{
            .buffer = idx_buffer,
            .offset = 0,
            .size = idx_size,
        }, false);
    }
    sdlc.SDL_EndGPUCopyPass(copy_pass);
    if (!sdlc.SDL_SubmitGPUCommandBuffer(upload_cmd_buffer)) return VertexBufferError.CopyCommandSubmitFailed;

    return .{
        .device = device,
        .num_indices = @intCast(indices.len),
        .vert_buf = vert_buffer,
        .idx_buf = idx_buffer,
    };
}

pub fn deinit(self: *@This()) void {
    sdlc.SDL_ReleaseGPUBuffer(self.device, self.vert_buf);
    sdlc.SDL_ReleaseGPUBuffer(self.device, self.idx_buf);
    self.* = undefined;
}

pub fn renderPass(self: *@This(), render_pass: *sdlc.SDL_GPURenderPass) void {
    const vert_buffers: [1]sdlc.SDL_GPUBufferBinding = .{sdlc.SDL_GPUBufferBinding{
        .buffer = self.vert_buf,
        .offset = 0,
    }};
    sdlc.SDL_BindGPUVertexBuffers(render_pass, 0, &vert_buffers, vert_buffers.len);

    const idx_buffers: [1]sdlc.SDL_GPUBufferBinding = .{sdlc.SDL_GPUBufferBinding{
        .buffer = self.idx_buf,
        .offset = 0,
    }};
    sdlc.SDL_BindGPUIndexBuffer(render_pass, &idx_buffers, sdlc.SDL_GPU_INDEXELEMENTSIZE_16BIT);
    sdlc.SDL_DrawGPUIndexedPrimitives(render_pass, self.num_indices, 1, 0, 0, 0);
}
