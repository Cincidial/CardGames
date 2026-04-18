const std = @import("std");

const Color = @import("root.zig").Color;
const Font = @import("root.zig").typography.Font;
const InstancedTextureRenderer = @import("root.zig").InstancedTextureRenderer;
const Mat4 = @import("root.zig").Mat4;
const PreAllocatedArrayError = @import("root.zig").PreAllocatedArray.PreAllocatedArrayError;
const Rect = @import("root.zig").Rect;
const sdlc = @import("root.zig").sdlc;
const Texture = @import("root.zig").Texture;
const Vec2 = @import("root.zig").Vec2;

pub const TextAlignment = enum {
    start, // Left for x, top for y
    center, // TODO: Multi-line support for y-axis centering
    end, // TODO: Do x
};

/// Where T is the vertex shader struct
/// TODO: Put this inside of the text struct so on import of text can cover it
pub fn FontRenderer(comptime T: type) type {
    return struct {
        comptime {
            const info = @typeInfo(T);
            std.debug.assert(info == .@"struct");
            std.debug.assert(std.meta.fieldInfo(T, .tex_coord).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .tex_dim).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .pos).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .scale).type == Vec2);
            std.debug.assert(std.meta.fieldInfo(T, .color).type == Color);
        }

        font: *const Font,
        renderer: InstancedTextureRenderer.InstancedTextureRenderer(T),

        pub fn init(allocater: std.mem.Allocator, font: *const Font, device: *sdlc.SDL_GPUDevice, texture: *Texture, sampler: *sdlc.SDL_GPUSampler, pipeline: *sdlc.SDL_GPUGraphicsPipeline) !@This() {
            return .{
                .font = font,
                .renderer = try InstancedTextureRenderer.InstancedTextureRenderer(T).init(allocater, device, pipeline, texture, sampler, 1000),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.renderer.deinit();
            self.* = undefined;
        }

        pub fn copyPass(self: *@This(), copy_pass: *sdlc.SDL_GPUCopyPass) !void {
            try self.renderer.copyPass(copy_pass);
        }

        // TODO: Better handling of uniforms, instead of just taking in a required Mat4
        pub fn renderPass(self: *@This(), cmd_buf: *sdlc.SDL_GPUCommandBuffer, render_pass: *sdlc.SDL_GPURenderPass, projection: Mat4) void {
            self.renderer.renderPass(cmd_buf, render_pass, projection);
        }
    };
}

/// Where T is the vertex shader struct
pub fn Text(comptime T: type) type {
    return struct {
        const InnerData = struct {
            char: u8,
            pos: Vec2,
            draw_data: InstancedTextureRenderer.InstancedTextureRenderer(T).InstanceArrayElementType,
        };

        allocater: std.mem.Allocator,
        font_renderer: *FontRenderer(T),
        text: []InnerData,
        scale: Vec2,
        color: Color,
        bounds: Rect,
        anchor: Vec2,
        align_x: TextAlignment,
        align_y: TextAlignment,
        is_uploaded: bool,

        pub fn init(allocater: std.mem.Allocator, font_renderer: *FontRenderer(T), string: []const u8, text_size: f32, color: Color) !@This() {
            std.debug.assert(string.len > 0);

            const scale = font_renderer.font.getScale(text_size);
            var cursor = Vec2.init(0, font_renderer.font.scaledLineHeight(scale));
            var text = try allocater.alloc(InnerData, string.len);
            var top: f32 = std.math.floatMin(f32);
            var bottom: f32 = std.math.floatMax(f32);

            for (string, 0..) |c, i| {
                if (c == 0) break;

                const glyph = font_renderer.font.glyphs[c];
                text[i].char = c;
                text[i].pos = cursor.subY(glyph.scaledDim(scale).y).add(glyph.offset(scale));

                top = @max(top, text[i].pos.addY(glyph.scaledDim(scale).y).y);
                bottom = @min(bottom, text[i].pos.y);
                cursor = cursor.add(glyph.cursorAdvance(scale));
            }
            const left = text[0].pos.x;
            const right = text[text.len - 1].pos.x + font_renderer.font.glyphs[text[text.len - 1].char].scaledDim(scale).x;
            const rect = Rect.init(left, top, right, bottom);

            // Translate to handle the offset from the glyphs so we are back to "start" alignment
            for (text) |*value| {
                value.pos = value.pos.sub(rect.topLeft());
            }

            return .{
                .allocater = allocater,
                .font_renderer = font_renderer,
                .text = text,
                .scale = Vec2.init(scale, scale),
                .color = color,
                .bounds = rect.translate(rect.topLeft().negate()),
                .anchor = Vec2.ZERO,
                .align_x = TextAlignment.start,
                .align_y = TextAlignment.start,
                .is_uploaded = false,
            };
        }

        pub fn deinit(self: *@This()) void {
            if (self.is_uploaded) {
                for (self.text) |*value| {
                    value.draw_data.removeFromArray();
                }
            }
            self.allocater.free(self.text);
            self.* = undefined;
        }

        pub fn reposition(self: *@This(), anchor: Vec2, align_x: TextAlignment, align_y: TextAlignment) void {
            var translation = anchor.sub(self.anchor);

            // Undo the original alignment
            switch (self.align_x) {
                .start => {},
                .center => translation = translation.addX(self.bounds.width / 2.0),
                .end => unreachable,
            }
            switch (self.align_y) {
                .start => {},
                .center => translation = translation.addY(self.bounds.height / 2.0),
                .end => translation = translation.subY(self.bounds.height),
            }

            // Apply the new alignment
            switch (align_x) {
                .start => {},
                .center => translation = translation.subX(self.bounds.width / 2.0),
                .end => unreachable,
            }
            switch (align_y) {
                .start => {},
                .center => translation = translation.subY(self.bounds.height / 2.0),
                .end => translation = translation.addY(self.bounds.height),
            }

            self.anchor = anchor;
            self.align_x = align_x;
            self.align_y = align_y;
            self.bounds = self.bounds.translate(translation);

            for (self.text) |*value| {
                value.pos = value.pos.add(translation);

                if (self.is_uploaded) {
                    value.draw_data.data.?.pos = value.pos;
                    value.draw_data.markUpdated();
                }
            }
        }

        pub fn recolor(self: *@This(), color: Color) void {
            self.color = color;

            if (self.is_uploaded) {
                for (self.text) |*value| {
                    value.draw_data.data.?.color = color;
                    value.draw_data.markUpdated();
                }
            }
        }

        pub fn changeText(self: *@This(), string: []const u8) !void {
            const original = self.*;
            self.deinit();

            self.* = try init(original.allocater, original.font_renderer, string, original.scale.x * original.font_renderer.font.size, original.color);
            self.reposition(original.anchor, original.align_x, original.align_y);

            if (original.is_uploaded) try self.uploadToGpu();
        }

        /// Tries to upload the drawing data to the GPU via the renderer. If this fails any characters that were succesfully written will be freed
        pub fn uploadToGpu(self: *@This()) !void {
            if (self.is_uploaded) return;

            var err: ?PreAllocatedArrayError = null;
            for (self.text) |*value| {
                self.font_renderer.renderer.instances.push(&value.draw_data) catch |e| {
                    err = e;
                    break;
                };

                value.draw_data.data.?.tex_coord = self.font_renderer.font.glyphs[value.char].tex_coord();
                value.draw_data.data.?.tex_dim = self.font_renderer.font.glyphs[value.char].tex_dimen();
                value.draw_data.data.?.pos = value.pos;
                value.draw_data.data.?.scale = self.scale;
                value.draw_data.data.?.color = self.color;
            }

            if (err) |e| {
                for (self.text) |*value| {
                    value.draw_data.removeFromArray();
                }
                return e;
            }
            self.is_uploaded = true;
        }

        pub fn removeFromGpu(self: *@This()) void {
            if (!self.is_uploaded) return;

            for (self.text) |*value| {
                value.draw_data.removeFromArray();
            }
            self.is_uploaded = false;
        }
    };
}
