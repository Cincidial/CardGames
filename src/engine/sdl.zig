const std = @import("std");

const sdlc = @import("root.zig").sdlc;

const App = struct {
    init: *const fn () anyerror!sdlc.SDL_AppResult,
    iterate: *const fn () anyerror!sdlc.SDL_AppResult,
    event: *const fn (e: sdlc.SDL_Event) anyerror!sdlc.SDL_AppResult,
    quit: *const fn (result: sdlc.SDL_AppResult) void,
    error_handler: *const fn (err: anyerror) sdlc.SDL_AppResult,
};

const sdl_log = std.log.scoped(.sdl);

var user_app: App = undefined;
var exe_path: ?[]const u8 = null;

pub fn startSdl(app: App) u8 {
    user_app = app;
    var empty_argv: [0:null]?[*:0]u8 = .{};
    return @truncate(@as(c_uint, @bitCast(sdlc.SDL_RunApp(empty_argv.len, @ptrCast(&empty_argv), sdlMainC, null))));
}

fn sdlMainC(argc: c_int, argv: ?[*:null]?[*:0]u8) callconv(.c) c_int {
    return sdlc.SDL_EnterAppMainCallbacks(argc, @ptrCast(argv), sdlAppInitC, sdlAppIterateC, sdlAppEventC, sdlAppQuitC);
}

fn sdlAppInitC(_: ?*?*anyopaque, _: c_int, _: ?[*:null]?[*:0]u8) callconv(.c) sdlc.SDL_AppResult {
    const platform: [*:0]const u8 = sdlc.SDL_GetPlatform();
    sdl_log.debug("SDL platform: {s}", .{platform});
    sdl_log.debug("SDL build time version: {d}.{d}.{d}", .{
        sdlc.SDL_MAJOR_VERSION,
        sdlc.SDL_MINOR_VERSION,
        sdlc.SDL_MICRO_VERSION,
    });
    sdl_log.debug("SDL build time revision: {s}", .{sdlc.SDL_REVISION});
    {
        const version = sdlc.SDL_GetVersion();
        sdl_log.debug("SDL runtime version: {d}.{d}.{d}", .{
            sdlc.SDL_VERSIONNUM_MAJOR(version),
            sdlc.SDL_VERSIONNUM_MINOR(version),
            sdlc.SDL_VERSIONNUM_MICRO(version),
        });
        const revision: [*:0]const u8 = sdlc.SDL_GetRevision();
        sdl_log.debug("SDL runtime revision: {s}", .{revision});
    }

    return user_app.init() catch |err| return user_app.error_handler(err);
}

fn sdlAppIterateC(_: ?*anyopaque) callconv(.c) sdlc.SDL_AppResult {
    return user_app.iterate() catch |err| return user_app.error_handler(err);
}

fn sdlAppEventC(_: ?*anyopaque, event: ?*sdlc.SDL_Event) callconv(.c) sdlc.SDL_AppResult {
    return user_app.event(event.?.*) catch |err| return user_app.error_handler(err);
}

fn sdlAppQuitC(_: ?*anyopaque, result: sdlc.SDL_AppResult) callconv(.c) void {
    user_app.quit(result);
}

// Zigification of lib methods
pub inline fn SDL_GetBasePath() []const u8 {
    if (exe_path == null) {
        exe_path = std.mem.span(sdlc.SDL_GetBasePath());
    }
    return exe_path.?;
}
