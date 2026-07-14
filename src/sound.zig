const util = @import("root").util;

const mach = @import("mach");
const Core = mach.Core;
const Mod = mach.Mod;
const audio = mach.sysaudio;

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

pub const Sound = @This();

pub const mach_module = .sound;

pub const mach_systems = .{
    .init,
    .deinit,
    .process,
    .load,
};

ctx: audio.Context,
player: audio.Player,
device: audio.Device,
thread: mach.Thread,

pub fn init(
    allocator: Allocator,
    sound: *Sound,
    core: *Core,
    core_mod: Mod(Core),
    snd_mod: Mod(Sound),
) !void {
    sound.* = undefined;
    sound.ctx = try .init(null, allocator, audio.Context.Options{
        .app_name = "[[Audio-Bea]]",
        .deviceChangeFn = @ptrCast(&device_change_callback),
        .user_data = @ptrCast(sound),
    });

    try sound.ctx.refresh();

    sound.device = sound.ctx.defaultDevice(.playback) orelse return error.NoPlaybackDevice;

    sound.player = try sound.ctx.createPlayer(
        sound.device,
        @ptrCast(&write_function_callback),
        audio.StreamOptions{
            .format = sound.device.preferredFormat(null),
            .media_role = .default,
            .sample_rate = 44100,
            .user_data = @ptrCast(sound),
        },
    );
    sound.thread = try mach.startThread(core, snd_mod.id.process, core_mod, .foobar);
    try sound.player.start();
}

pub fn deinit(sound: *Sound) void {
    sound.thread.join();
    sound.player.deinit();
    sound.ctx.deinit();
}

fn write_function_callback(sound: *Sound, range: []u8) void {
    _ = sound;
    @memset(range, 0);
}

pub fn process(io: Io, sound: *Sound) void {
    _ = sound;
    util.sleep.precise(io, .fromMilliseconds(500), .real) catch unreachable;
}

pub fn load() void {}

fn device_change_callback(sound: *Sound) !void {
    // when the backend is just switching or the device we are using is not the one lost
    sound.ctx.refresh() catch @panic("");
    const device = sound.ctx.defaultDevice(.playback) orelse @panic("");
    if(std.mem.eql(u8, device.id, sound.device.id)) return;
    
    sound.player.deinit();
    sound.device = sound.ctx.defaultDevice(.playback) orelse return;

    sound.player = sound.ctx.createPlayer(
        sound.device,
        @ptrCast(&write_function_callback),
        audio.StreamOptions{
            .format = sound.device.preferredFormat(null),
            .media_role = .default,
            .sample_rate = 44100,
            .user_data = @ptrCast(sound),
        },
    ) catch return;

    sound.player.start() catch return;
}
