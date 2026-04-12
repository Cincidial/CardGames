const sdlc = @import("root.zig").sdlc;

const DataBufferError = error{
    UnableToCreateTransferBuffer,
    UnableToCreateGpuBuffer,
    NotEnoughMemory,
    CannotMapTransferBuffer,
};

device: *sdlc.SDL_GPUDevice,
size: usize,
transfer_buf: *sdlc.SDL_GPUTransferBuffer,
gpu_buf: *sdlc.SDL_GPUBuffer,

pub fn init(device: *sdlc.SDL_GPUDevice, size: usize) DataBufferError!@This() {
    const tbuf = sdlc.SDL_CreateGPUTransferBuffer(device, &sdlc.SDL_GPUTransferBufferCreateInfo{
        .usage = sdlc.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
        .size = @intCast(size),
    }) orelse return DataBufferError.UnableToCreateTransferBuffer;
    errdefer sdlc.SDL_ReleaseGPUTransferBuffer(device, tbuf);

    const gpu_buf = sdlc.SDL_CreateGPUBuffer(device, &sdlc.SDL_GPUBufferCreateInfo{
        .usage = sdlc.SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
        .size = @intCast(size),
    }) orelse return DataBufferError.UnableToCreateGpuBuffer;
    errdefer sdlc.SDL_ReleaseGPUBuffer(device, gpu_buf);

    return .{
        .device = device,
        .size = size,
        .transfer_buf = tbuf,
        .gpu_buf = gpu_buf,
    };
}

pub fn deinit(self: *@This()) void {
    sdlc.SDL_ReleaseGPUTransferBuffer(self.device, self.transfer_buf);
    sdlc.SDL_ReleaseGPUBuffer(self.device, self.gpu_buf);
    self.* = undefined;
}

pub fn upload(self: *@This(), copy_pass: *sdlc.SDL_GPUCopyPass, comptime T: type, data: []const T) DataBufferError!void {
    const data_byte_size = data.len * @sizeOf(T);
    if (data_byte_size > self.size) return DataBufferError.NotEnoughMemory;

    const ptr = sdlc.SDL_MapGPUTransferBuffer(self.device, self.transfer_buf, true) orelse return DataBufferError.CannotMapTransferBuffer;
    _ = sdlc.memcpy(ptr, data.ptr, data_byte_size);
    sdlc.SDL_UnmapGPUTransferBuffer(self.device, self.transfer_buf);

    sdlc.SDL_UploadToGPUBuffer(copy_pass, &sdlc.SDL_GPUTransferBufferLocation{
        .transfer_buffer = self.transfer_buf,
        .offset = 0,
    }, &sdlc.SDL_GPUBufferRegion{
        .buffer = self.gpu_buf,
        .offset = 0,
        .size = @intCast(data_byte_size),
    }, true);
}

pub fn bind(self: *@This(), render_pass: *sdlc.SDL_GPURenderPass, first_slot: u32) void {
    sdlc.SDL_BindGPUVertexStorageBuffers(render_pass, first_slot, &self.gpu_buf, 1);
}
