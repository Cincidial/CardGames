const std = @import("std");

const Color = @import("engine").Color;
const Font = @import("engine").typography.Font;
const Mat4 = @import("engine").Mat4;
const sdl = @import("engine").sdl;
const sdlc = @import("engine").sdlc;
const TextAlignment = @import("engine").Text.TextAlignment;
const Texture = @import("engine").Texture;
const Vec2 = @import("engine").Vec2;

const context = @import("context.zig");
const shaders = @import("shaders/shaders.zig");

const SDLError = error{
    UnableToInit,
    UnableToCreateWindow,
    UnableToCreateDevice,
    UnableToClaimWindow,
    UnableToCreateSampler,
    UnableToCreatePipeline,
    UnableToAquireCmdBuf,
    UnableToAquireSwapChain,
    UnableToSubmitGPUCmdBuf,
};

pub fn main(preset: std.process.Init) !u8 {
    context.perm_arena = preset.arena.allocator();
    context.gpa = preset.gpa;
    context.io = preset.io;
    context.prng = .init(blk: {
        var buffer: [8]u8 = undefined;
        break :blk std.mem.readInt(u64, &buffer, .native);
    });

    return sdl.startSdl(.{
        .init = init,
        .iterate = iterate,
        .event = event,
        .quit = quit,
        .error_handler = errorHandler,
    });
}

var init_complete = false;
fn init() !sdlc.SDL_AppResult {
    // Window and device creation
    if (!sdlc.SDL_Init(sdlc.SDL_INIT_VIDEO | sdlc.SDL_INIT_AUDIO)) return SDLError.UnableToInit;

    context.window = sdlc.SDL_CreateWindow("Card Games", @trunc(context.window_dim.x), @trunc(context.window_dim.x), 0) orelse return SDLError.UnableToCreateWindow;
    errdefer sdlc.SDL_DestroyWindow(context.window);

    context.gpu_device = sdlc.SDL_CreateGPUDevice(sdlc.SDL_GPU_SHADERFORMAT_SPIRV | sdlc.SDL_GPU_SHADERFORMAT_DXIL | sdlc.SDL_GPU_SHADERFORMAT_MSL, true, null) orelse return SDLError.UnableToCreateDevice;
    errdefer sdlc.SDL_DestroyGPUDevice(context.gpu_device);

    if (!sdlc.SDL_ClaimWindowForGPUDevice(context.gpu_device, context.window)) return SDLError.UnableToClaimWindow;
    errdefer sdlc.SDL_ReleaseWindowFromGPUDevice(context.gpu_device, context.window);

    context.audio_device = try .init();
    errdefer context.audio_device.deinit();

    // Sampler creation
    context.sampler = sdlc.SDL_CreateGPUSampler(context.gpu_device, &sdlc.SDL_GPUSamplerCreateInfo{
        .min_filter = sdlc.SDL_GPU_FILTER_NEAREST,
        .mag_filter = sdlc.SDL_GPU_FILTER_NEAREST,
        .mipmap_mode = sdlc.SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
        .address_mode_u = sdlc.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
        .address_mode_v = sdlc.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
    }) orelse return SDLError.UnableToCreateSampler;
    errdefer sdlc.SDL_ReleaseGPUSampler(context.gpu_device, context.sampler);

    // Shader creation
    const vert_text_shader = try shaders.VertText.createShader(context.gpu_device, 0, 2, 1, 0);
    defer sdlc.SDL_ReleaseGPUShader(context.gpu_device, vert_text_shader);

    const frag_text_shader = try shaders.FragText.createShader(context.gpu_device, 1, 0, 0, 0);
    defer sdlc.SDL_ReleaseGPUShader(context.gpu_device, frag_text_shader);

    // Pipeline creation
    const standard_rasterizer_state = sdlc.SDL_GPURasterizerState{
        .fill_mode = sdlc.SDL_GPU_FILLMODE_FILL,
        .cull_mode = sdlc.SDL_GPU_CULLMODE_BACK,
        .front_face = sdlc.SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
    };
    const standard_blending_color_target_descs: [1]sdlc.SDL_GPUColorTargetDescription = .{
        sdlc.SDL_GPUColorTargetDescription{
            .blend_state = sdlc.SDL_GPUColorTargetBlendState{
                .enable_blend = true,
                .color_blend_op = sdlc.SDL_GPU_BLENDOP_ADD,
                .src_color_blendfactor = sdlc.SDL_GPU_BLENDFACTOR_SRC_ALPHA,
                .dst_color_blendfactor = sdlc.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                .alpha_blend_op = sdlc.SDL_GPU_BLENDOP_ADD,
                .src_alpha_blendfactor = sdlc.SDL_GPU_BLENDFACTOR_SRC_ALPHA,
                .dst_alpha_blendfactor = sdlc.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
            },
            .format = sdlc.SDL_GetGPUSwapchainTextureFormat(context.gpu_device, context.window),
        },
    };
    const pipeline_standard_blending_target_info = sdlc.SDL_GPUGraphicsPipelineTargetInfo{
        .color_target_descriptions = &standard_blending_color_target_descs,
        .num_color_targets = standard_blending_color_target_descs.len,
    };

    context.text_pipeline = sdlc.SDL_CreateGPUGraphicsPipeline(context.gpu_device, &sdlc.SDL_GPUGraphicsPipelineCreateInfo{
        .vertex_shader = vert_text_shader,
        .fragment_shader = frag_text_shader,
        .primitive_type = sdlc.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
        .rasterizer_state = standard_rasterizer_state,
        .target_info = pipeline_standard_blending_target_info,
    }) orelse return SDLError.UnableToCreatePipeline;
    errdefer sdlc.SDL_ReleaseGPUGraphicsPipeline(context.gpu_device, context.text_pipeline);

    // Asset creation
    context.resource_manager = .init(context.io, context.gpa, context.gpu_device, &context.audio_device);
    context.text_render_context = .{
        .allocator = context.gpa,
        .font = try context.resource_manager.getFont("Default.fnt"),
        .device = context.gpu_device,
        .texture_sampler = .{
            .texture = try context.resource_manager.getTexture("DefaultFont.png"),
            .binding = .{
                .texture = (try context.resource_manager.getTexture("DefaultFont.png")).gpu_texture,
                .sampler = context.sampler,
            },
        },
        .pipeline = context.text_pipeline,
    };

    context.title = try .init(.{
        .context = context.text_render_context,
        .text_size = 72,
        .color = Color.GREEN,
        .outline_color = Color.BLACK,
        .anchor = Vec2.fromUiRatio(context.window_dim, 0.5, 0.5),
        .align_x = TextAlignment.center,
    }, "Test");

    // Projection
    context.projection = Mat4.orthographic(context.window_dim.x / 2, context.window_dim.x / -2, context.window_dim.y / 2, context.window_dim.y / -2);

    // Finished
    init_complete = true;
    return sdlc.SDL_APP_CONTINUE;
}

fn iterate() !sdlc.SDL_AppResult {
    // Rendering, probably have this in another method if it's larger
    const cmd_buf = sdlc.SDL_AcquireGPUCommandBuffer(context.gpu_device) orelse return SDLError.UnableToAquireCmdBuf;

    var swapchain_tex: ?*sdlc.SDL_GPUTexture = undefined;
    if (!sdlc.SDL_WaitAndAcquireGPUSwapchainTexture(cmd_buf, context.window, &swapchain_tex, null, null)) return SDLError.UnableToAquireSwapChain;

    if (swapchain_tex) |tex| {
        const colorTargetInfo = sdlc.SDL_GPUColorTargetInfo{
            .texture = tex,
            .clear_color = sdlc.SDL_FColor{ .r = 0.4, .g = 0.6, .b = 0.9, .a = 1.0 },
            .load_op = sdlc.SDL_GPU_LOADOP_CLEAR,
            .store_op = sdlc.SDL_GPU_STOREOP_STORE,
        };
        const cpy_pass = sdlc.SDL_BeginGPUCopyPass(cmd_buf).?;
        {
            try context.title.copyPass(cpy_pass);
        }
        sdlc.SDL_EndGPUCopyPass(cpy_pass);

        const render_pass = sdlc.SDL_BeginGPURenderPass(cmd_buf, &colorTargetInfo, 1, null).?;
        {
            context.title.renderPass(cmd_buf, render_pass, context.projection);
        }
        sdlc.SDL_EndGPURenderPass(render_pass);
    }
    if (!sdlc.SDL_SubmitGPUCommandBuffer(cmd_buf)) return SDLError.UnableToSubmitGPUCmdBuf;

    return sdlc.SDL_APP_CONTINUE;
}

fn event(e: sdlc.SDL_Event) !sdlc.SDL_AppResult {
    switch (e.type) {
        sdlc.SDL_EVENT_QUIT => return sdlc.SDL_APP_SUCCESS,
        sdlc.SDL_EVENT_KEY_DOWN => {
            if (e.key.scancode == sdlc.SDL_SCANCODE_ESCAPE) return sdlc.SDL_APP_SUCCESS;
        },
        else => return sdlc.SDL_APP_CONTINUE,
    }

    return sdlc.SDL_APP_CONTINUE;
}

fn quit(_: sdlc.SDL_AppResult) void {
    if (!init_complete) return;

    context.title.deinit();
    context.resource_manager.deinit();

    sdlc.SDL_ReleaseGPUGraphicsPipeline(context.gpu_device, context.text_pipeline);
    sdlc.SDL_ReleaseGPUSampler(context.gpu_device, context.sampler);

    context.audio_device.deinit();
    sdlc.SDL_ReleaseWindowFromGPUDevice(context.gpu_device, context.window);
    sdlc.SDL_DestroyGPUDevice(context.gpu_device);
    sdlc.SDL_DestroyWindow(context.window);

    init_complete = false;
}

fn errorHandler(err: anyerror) sdlc.SDL_AppResult {
    context.log.err("Error Handler: {any}\n", .{err});

    const sdl_error = sdlc.SDL_GetError();
    if (sdl_error != null and sdl_error[0] != 0) {
        context.log.err("SDL: {s}\n", .{sdl_error});
    }
    std.debug.dumpCurrentStackTrace(.{});

    return sdlc.SDL_APP_FAILURE;
}
