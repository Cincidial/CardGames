const Allocater = @import("std").mem.Allocator;

const DataBuffer = @import("root.zig").DataBuffer;
const Mat4 = @import("root.zig").Mat4;
const PreAllocatedArray = @import("root.zig").PreAllocatedArray;
const sdlc = @import("root.zig").sdlc;
const Texture = @import("root.zig").Texture;

pub fn InstancedTextureRenderer(comptime T: type) type {
    return struct {
        const InstanceArrayType = PreAllocatedArray.PreAllocatedArray(T);
        pub const InstanceArrayElementType = InstanceArrayType.ElementWrapper;

        device: *sdlc.SDL_GPUDevice,
        pipeline: *sdlc.SDL_GPUGraphicsPipeline,
        texture: *Texture,
        sampler: *sdlc.SDL_GPUSampler,
        gpu_data_buffer: DataBuffer,
        instances: InstanceArrayType,

        /// The allocater is passed through to the underlying PreAllocatedArray
        pub fn init(allocater: Allocater, device: *sdlc.SDL_GPUDevice, pipeline: *sdlc.SDL_GPUGraphicsPipeline, texture: *Texture, sampler: *sdlc.SDL_GPUSampler, max_instances: usize) !@This() {
            return .{
                .device = device,
                .pipeline = pipeline,
                .texture = texture,
                .sampler = sampler,
                .gpu_data_buffer = try DataBuffer.init(device, max_instances * @sizeOf(T)),
                .instances = try InstanceArrayType.init(allocater, max_instances),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.gpu_data_buffer.deinit();
            self.instances.deinit();

            self.* = undefined;
        }

        pub fn copyPass(self: *@This(), copy_pass: *sdlc.SDL_GPUCopyPass) !void {
            if (!self.instances.has_changes) return;

            try self.gpu_data_buffer.upload(copy_pass, T, self.instances.getInUseDataSlice());
            self.instances.has_changes = false;
        }

        // TODO: Better handling of uniforms, instead of just taking in a required Mat4
        pub fn renderPass(self: *@This(), cmd_buf: *sdlc.SDL_GPUCommandBuffer, render_pass: *sdlc.SDL_GPURenderPass, projection: Mat4) void {
            sdlc.SDL_BindGPUGraphicsPipeline(render_pass, self.pipeline);
            self.gpu_data_buffer.bind(render_pass, 0);
            sdlc.SDL_BindGPUFragmentSamplers(render_pass, 0, &sdlc.SDL_GPUTextureSamplerBinding{
                .texture = self.texture.gpu_texture,
                .sampler = self.sampler,
            }, 1);
            projection.uniformBind(cmd_buf, 0);
            self.texture.dimensions.uniformBind(cmd_buf, 1);
            sdlc.SDL_DrawGPUPrimitives(render_pass, @intCast(6 * self.instances.in_use_size), 1, 0, 0); // 6 primitives to form a quad per instance
        }
    };
}
