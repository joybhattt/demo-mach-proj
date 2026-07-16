// general aliases in all mach modules

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const print = std.debug.print;
const assert = std.debug.assert;

const mach = @import("root").mach;
const Mod = mach.Mod;
const Core = mach.Core;
const ObjID = mach.ObjectID;
const FnID = mach.FunctionID;

const config = @import("config.zig");
const util = @import("root").util;

pub const App = @This();
const Gfx = @import("root").Gfx;
const Sound = @import("root").Sound;
const Context = @import("root").Context;

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

window_id: ObjID,
thread: mach.Thread,
last_frame: Io.Timestamp,
flip: bool,
current_context: Context.Enum,

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

    var grp: Io.Group = .init;
    gfx_mod.concurrentGroup(&grp, .init) catch unreachable;
    snd_mod.concurrentGroup(&grp, .init) catch unreachable;
    std.Thread.yield() catch unreachable;
    grp.await(io) catch unreachable;

    // set up the context of the application
    ctx_mod.call(.init);
    app.flip = true;
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
    if (config.App.frame_us > delta_us) {
        const remaining_us = config.App.frame_us - delta_us;
        util.sleep.precise(io, .fromMicroseconds(remaining_us), .real) catch unreachable;
    }
    app.last_frame = .now(io, .real);

    ctx_mod.call(.process);

    _ = snd_mod.concurrent(.load) catch unreachable;
    gfx_mod.call(.load);

    // render loop at half frame_rate
    if (app.flip) gfx_mod.call(.process);
    app.flip = !app.flip;
}
