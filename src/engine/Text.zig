const std = @import("std");

const Color = @import("root.zig").Color;
const DataBuffer = @import("root.zig").DataBuffer;
const Font = @import("root.zig").typography.Font;
const InstancedTextureRenderer = @import("root.zig").InstancedTextureRenderer;
const Mat4 = @import("root.zig").Mat4;
const PreAllocatedArrayError = @import("root.zig").PreAllocatedArray.PreAllocatedArrayError;
const Rect = @import("root.zig").Rect;
const sdlc = @import("root.zig").sdlc;
const TextureSamplerBinding = @import("root.zig").TextureSamplerBinding;
const Vec2 = @import("root.zig").Vec2;
const Vec3 = @import("root.zig").Vec3;
const UIKitData = @import("root.zig").UIKit.Data;

pub const TextAlignment = enum {
    start, // Left for x, top for y
    center, // TODO: Multi-line support for y-axis centering
    end, // TODO: Do x
};

// Data that may be commonly used to render text
pub const TextRenderContext = struct {
    allocator: std.mem.Allocator,
    device: *sdlc.SDL_GPUDevice,
    pipeline: *sdlc.SDL_GPUGraphicsPipeline,
    texture_sampler: TextureSamplerBinding,
    font: *const Font,
};

/// Where T is the vertex shader data struct
pub fn Text(comptime T: type) type {
    return struct {
        comptime {
            const info = @typeInfo(T);
            std.debug.assert(info == .@"struct");
            std.debug.assert(std.meta.fieldInfo(T, .tex_coord).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .tex_dim).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .pos).type == Vec3);
            std.debug.assert(std.meta.fieldInfo(T, .color).type == Color);
            std.debug.assert(std.meta.fieldInfo(T, .outline_size).type == f32);
            std.debug.assert(std.meta.fieldInfo(T, .outline_color).type == Color);
            std.debug.assert(std.meta.fieldInfo(T, .scale).type == Vec2);
        }

        pub const Configuration = struct {
            context: TextRenderContext,
            text_size: f32 = 0, // Setting a size of 0 or less will use the fonts natural size
            color: Color = .BLACK,
            anchor: Vec2 = .ZERO,
            align_x: TextAlignment = .start,
            align_y: TextAlignment = .start,
            outline_size: f32 = 0,
            outline_color: Color = Color.TRANSPARENT,
        };

        config: Configuration,
        gpu_data_buffer: DataBuffer,
        text: []T,
        ui_kit: UIKitData,

        pub fn init(config: Configuration, string: []const u8) !@This() {
            std.debug.assert(string.len > 0);

            const text_size = if (config.text_size <= 0) config.context.font.size else config.text_size;
            const scale = config.context.font.getScale(text_size);
            const scale_vec = Vec2.init(scale, scale);
            const padding_vec = Vec2.init(config.outline_size, config.outline_size).multScalar(scale);

            var gpu_buffer = try DataBuffer.init(config.context.device, string.len * @sizeOf(T));
            errdefer gpu_buffer.deinit();

            var text = try config.context.allocator.alloc(T, string.len);
            errdefer config.context.allocator.free(text);

            var cursor = Vec3.init(-config.context.font.glyphs[0].x_offset + padding_vec.x, config.context.font.scaledLineHeight(scale), 0);
            var top: f32 = std.math.floatMin(f32);
            var bottom: f32 = std.math.floatMax(f32);

            for (string, 0..) |c, i| {
                if (c == 0) break;
                const glyph = config.context.font.glyphs[c];

                text[i].tex_coord = glyph.tex_coord();
                text[i].tex_dim = glyph.tex_dimen();
                text[i].pos = cursor.subY(glyph.scaledDim(scale).y).addVec2(glyph.offset(scale));
                text[i].color = config.color;
                text[i].outline_size = config.outline_size;
                text[i].outline_color = config.outline_color;
                text[i].scale = scale_vec;

                top = @max(top, text[i].pos.addY(glyph.scaledDim(scale).y).y); // Don't undo the offset change as we want the value to the top of the character, not the cursor start
                bottom = @min(bottom, text[i].pos.y);
                cursor = cursor.addX(glyph.cursorAdvance(scale) + (padding_vec.x * 2));
            }
            const left = text[0].pos.x;
            const right = text[text.len - 1].pos.x + config.context.font.glyphs[string[string.len - 1]].scaledDim(scale).x; // Same here, we just want the right side of the char, so keep the offset
            const rect = Rect.init(left, top, right, bottom);

            const anchor = config.anchor;
            const align_x = config.align_x;
            const align_y = config.align_y;
            var result: Text(T) = .{
                .config = config,
                .gpu_data_buffer = gpu_buffer,
                .text = text,
                .ui_kit = .{
                    .has_changes = true,
                    .bounds = rect.translate(rect.topLeft().negate()), // Make the bounds match the glyphs start alignment
                },
            };

            result.config.anchor = .ZERO;
            result.config.align_x = .start;
            result.config.align_y = .start;
            result.reposition(anchor, align_x, align_y);
            return result;
        }

        pub fn deinit(self: *@This()) void {
            self.config.context.allocator.free(self.text);
            self.gpu_data_buffer.deinit();
            self.* = undefined;
        }

        pub fn reposition(self: *@This(), anchor: Vec2, align_x: TextAlignment, align_y: TextAlignment) void {
            var translation = anchor.sub(self.config.anchor);

            // Undo the original alignment
            switch (self.config.align_x) {
                .start => {},
                .center => translation = translation.addX(self.ui_kit.bounds.width / 2.0),
                .end => unreachable,
            }
            switch (self.config.align_y) {
                .start => {},
                .center => translation = translation.subY(self.ui_kit.bounds.height / 2.0),
                .end => translation = translation.subY(self.ui_kit.bounds.height),
            }

            // Apply the new alignment
            switch (align_x) {
                .start => {},
                .center => translation = translation.subX(self.ui_kit.bounds.width / 2.0),
                .end => unreachable,
            }
            switch (align_y) {
                .start => {},
                .center => translation = translation.addY(self.ui_kit.bounds.height / 2.0),
                .end => translation = translation.addY(self.ui_kit.bounds.height),
            }

            self.config.anchor = anchor;
            self.config.align_x = align_x;
            self.config.align_y = align_y;
            self.ui_kit.bounds = self.ui_kit.bounds.translate(translation);

            for (self.text) |*value| {
                value.pos = value.pos.addVec2(translation);
            }
            self.ui_kit.has_changes = true;
        }

        pub fn changeText(self: *@This(), string: []const u8) !void {
            const config = self.config;
            self.deinit();
            self.* = try .init(config, string);
        }

        pub fn changeOutlineColor(self: *@This(), color: Color) void {
            if (!std.meta.eql(self.config.outline_color, color)) {
                self.config.outline_color = color;
                for (self.text) |*value| {
                    value.outline_color = color;
                }

                self.has_changes = true;
            }
        }

        pub fn copyPass(self: *@This(), copy_pass: *sdlc.SDL_GPUCopyPass) !void {
            if (!self.ui_kit.has_changes) return;

            try self.gpu_data_buffer.upload(copy_pass, T, self.text);
            self.ui_kit.has_changes = false;
        }

        // TODO: Better handling of uniforms, instead of just taking in a required Mat4
        pub fn renderPass(self: *@This(), cmd_buf: *sdlc.SDL_GPUCommandBuffer, render_pass: *sdlc.SDL_GPURenderPass, projection: Mat4) void {
            sdlc.SDL_BindGPUGraphicsPipeline(render_pass, self.config.context.pipeline);
            self.gpu_data_buffer.bind(render_pass, 0);
            sdlc.SDL_BindGPUFragmentSamplers(render_pass, 0, &self.config.context.texture_sampler.binding, 1);
            projection.uniformBind(cmd_buf, 0);
            self.config.context.texture_sampler.texture.dimensions.uniformBind(cmd_buf, 1);
            sdlc.SDL_DrawGPUPrimitives(render_pass, @intCast(6 * self.text.len), 1, 0, 0); // 6 primitives to form a quad per instance. TODO: create a function in sdl.zig for this logic
        }
    };
}
