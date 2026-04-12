const sdlc = @import("root.zig").sdlc;

pub const AudioError = error{
    UnableToOpenAudioDevice,
    UnableToLoadWavFile,
    UnableToCreateStream,
    UnableToBindStream,
    UnableToPutStreamData,
};

pub const AudioDevice = struct {
    device_id: sdlc.SDL_AudioDeviceID,

    pub fn init() AudioError!@This() {
        const device = sdlc.SDL_OpenAudioDevice(sdlc.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, null);
        if (device == 0) return AudioError.UnableToOpenAudioDevice;

        return .{ .device_id = device };
    }

    pub fn deinit(self: *@This()) void {
        sdlc.SDL_CloseAudioDevice(self.device_id);
        self.* = undefined;
    }
};

pub const AudioStream = struct {
    wav_data: []u8,
    stream: *sdlc.SDL_AudioStream,

    pub fn init(wav_path: []const u8, device: *const AudioDevice) AudioError!@This() {
        var spec: sdlc.SDL_AudioSpec = undefined;
        var wav_data_ptr: [*]u8 = undefined;
        var wav_data_len: u32 = undefined;
        if (!sdlc.SDL_LoadWAV(wav_path.ptr, &spec, @ptrCast(&wav_data_ptr), &wav_data_len)) return AudioError.UnableToLoadWavFile;

        const stream = sdlc.SDL_CreateAudioStream(&spec, null) orelse return AudioError.UnableToCreateStream;
        if (!sdlc.SDL_BindAudioStream(device.device_id, stream)) return AudioError.UnableToBindStream;

        return .{ .wav_data = wav_data_ptr[0..wav_data_len], .stream = stream };
    }

    pub fn deinit(self: *@This()) void {
        sdlc.SDL_DestroyAudioStream(self.stream);
        sdlc.SDL_free(self.wav_data.ptr);
        self.* = undefined;
    }

    pub fn playOnce(self: *@This()) AudioError!void {
        if (!sdlc.SDL_PutAudioStreamData(self.stream, self.wav_data.ptr, @intCast(self.wav_data.len))) return AudioError.UnableToPutStreamData;
    }
};
