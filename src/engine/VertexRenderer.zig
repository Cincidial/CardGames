const std = @import("std");

const Mat4 = @import("root.zig").Mat4;
const sdlc = @import("root.zig").sdlc;
const Texture = @import("root.zig").Texture;
const VertexBuffer = @import("root.zig").VertexBuffer;

pipeline: *sdlc.SDL_GPUGraphicsPipeline,
vertex_buffer: VertexBuffer,

/// Ordered as TL, BL, BR, TR
pub fn initQuad(comptime T: type, device: *sdlc.SDL_GPUDevice, pipeline: *sdlc.SDL_GPUGraphicsPipeline, data: []const T) !@This() {
    std.debug.assert(data.len == 4);
    return .{
        .pipeline = pipeline,
        .vertex_buffer = try VertexBuffer.init(T, device, data, &.{ 0, 1, 2, 2, 3, 0 }),
    };
}

pub fn deinit(self: *@This()) void {
    self.vertex_buffer.deinit();
    self.* = undefined;
}

pub fn renderPass(
    self: *@This(),
    cmd_buf: *sdlc.SDL_GPUCommandBuffer,
    render_pass: *sdlc.SDL_GPURenderPass,
    texture_sampler_bindings: []const sdlc.SDL_GPUTextureSamplerBinding,
    projection: Mat4,
) void {
    sdlc.SDL_BindGPUGraphicsPipeline(render_pass, self.pipeline);
    sdlc.SDL_BindGPUFragmentSamplers(render_pass, 0, texture_sampler_bindings.ptr, @intCast(texture_sampler_bindings.len));
    projection.uniformBind(cmd_buf, 0);
    self.vertex_buffer.renderPass(render_pass);
}
