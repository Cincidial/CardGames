const std = @import("std");

const sdl = @import("engine").sdl;
const sdlc = @import("engine").sdlc;

const context = @import("context.zig");

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

pub fn main() !u8 {
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
    context.prng = .init(blk: { // TODO: put into engine
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    if (!sdlc.SDL_Init(sdlc.SDL_INIT_VIDEO | sdlc.SDL_INIT_AUDIO)) return SDLError.UnableToInit;

    context.window = sdlc.SDL_CreateWindow("Card Games", @intFromFloat(context.window_dim.x), @intFromFloat(context.window_dim.x), 0) orelse return SDLError.UnableToCreateWindow;
    errdefer sdlc.SDL_DestroyWindow(context.window);

    context.gpu_device = sdlc.SDL_CreateGPUDevice(sdlc.SDL_GPU_SHADERFORMAT_SPIRV | sdlc.SDL_GPU_SHADERFORMAT_DXIL | sdlc.SDL_GPU_SHADERFORMAT_MSL, true, null) orelse return SDLError.UnableToCreateDevice;
    errdefer sdlc.SDL_DestroyGPUDevice(context.gpu_device);

    if (!sdlc.SDL_ClaimWindowForGPUDevice(context.gpu_device, context.window)) return SDLError.UnableToClaimWindow;
    errdefer sdlc.SDL_ReleaseWindowFromGPUDevice(context.gpu_device, context.window);

    context.audio_device = try .init();
    errdefer context.audio_device.deinit();

    context.sampler = sdlc.SDL_CreateGPUSampler(context.gpu_device, &sdlc.SDL_GPUSamplerCreateInfo{
        .min_filter = sdlc.SDL_GPU_FILTER_NEAREST,
        .mag_filter = sdlc.SDL_GPU_FILTER_NEAREST,
        .mipmap_mode = sdlc.SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
        .address_mode_u = sdlc.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
        .address_mode_v = sdlc.SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
    }) orelse return SDLError.UnableToCreateSampler;
    errdefer sdlc.SDL_ReleaseGPUSampler(context.gpu_device, context.sampler);

    init_complete = true;
    return sdlc.SDL_APP_CONTINUE;
}

fn iterate() !sdlc.SDL_AppResult {
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
    std.debug.dumpCurrentStackTrace(null);

    return sdlc.SDL_APP_FAILURE;
}
