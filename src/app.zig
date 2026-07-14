const std = @import("std");
const Io = std.Io;

const mach = @import("root").mach;
const Core = mach.Core;
const Mod = mach.Mod;

const config = @import("config.zig");
const util = @import("root").util;

pub const App = @This();
const Gfx = @import("gfx.zig");
const Sound = @import("sound.zig");
const Context = @import("context.zig");

pub const mach_module = .app;

pub const mach_systems = .{
    .main,
    .init,
    .deinit,
    .process,
};

pub const main = mach.schedule(.{
    .{ Core, .init },
    .{ App, .init },
    .{ Core, .main },
});

window_id: mach.ObjectID,
thread: mach.Thread,
last_frame: Io.Timestamp,
switch_context_to: ?config.Context.Enum,

pub fn init(
    io: Io,
    app: *App,
    core: *Core,
    app_mod: Mod(App),
    core_mod: Mod(Core),
    gfx_mod: Mod(Gfx),
    ctx_mod: Mod(Context),
    snd_mod: Mod(Sound),
) !void {
    app.* = undefined;

    core.on_exit = app_mod.id.deinit;
    app.window_id = try core.windows.new(.{
        .title = config.Window.title,
        .height = config.Window.height,
        .width = config.Window.width,
        .transparent = config.Window.transparent,
        .vsync_mode = config.Window.vsync_mode,
        .on_render = gfx_mod.id.on_render,
    });
    app.switch_context_to = null;
    gfx_mod.call(.init);
    snd_mod.call(.init);
    // set up the context of the application
    ctx_mod.call(.init);
    app.last_frame = .now(io, .real);
    app.thread = try mach.startThread(core, app_mod.id.process, core_mod, .foobar);
}

pub fn deinit(
    io: Io,
    app: *App,
    ctx_mod: Mod(Context),
    gfx_mod: Mod(Gfx),
    snd_mod: Mod(Sound),
) void {
    app.thread.join();
    ctx_mod.call(.deinit);

    var grp: Io.Group = .init;
    gfx_mod.concurrentGroup(&grp, .deinit) catch unreachable;
    snd_mod.concurrentGroup(&grp, .deinit) catch unreachable;
    std.Thread.yield() catch unreachable;
    grp.await(io) catch unreachable;
}

pub fn process(
    io: Io,
    app: *App,
    ctx_mod: Mod(Context),
    gfx_mod: Mod(Gfx),
    snd_mod: Mod(Sound),
) void {
    const delta_us = app.last_frame.untilNow(io, .real).toMicroseconds();
    if (config.Tick.frame_us > delta_us) {
        const remaining_us = config.Tick.frame_us - delta_us;
        util.sleep.precise(io, .fromMicroseconds(remaining_us), .real) catch unreachable;
    }
    app.last_frame = .now(io, .real);

    // needs a mutex and then copies the events buffer
    var network_events = ctx_mod.concurrent(.fetchNetEvents) catch unreachable;
    ctx_mod.call(.pollInputEvents);
    network_events.await(io);

    ctx_mod.call(.process);

    // is processed during or right after os callback
    _ = snd_mod.concurrent(.load) catch unreachable;
    gfx_mod.call(.load);
    gfx_mod.call(.process);
}
