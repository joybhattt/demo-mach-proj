const mach = @import("root").mach;
const Core = mach.Core;
const Mod = mach.Mod;

const Context = @This();
const Gfx = @import("../gfx.zig");
const Sound = @import("../sound.zig");
const App = @import("../app.zig");

const mach_module = .dummy;

const mach_systems = .{
    .init,
    .deinit,
    .physics,
    .logic,
};

pub inline fn init(
    self: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    self.* = undefined;
    _ = core;
    _ = app;
    _ = gfx;
    _ = snd;
}

pub inline fn deinit(
    self: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    _ = self;
    _ = core;
    _ = app;
    _ = gfx;
    _ = snd;
}

pub fn recordInputEvent(self: *Context, event: Core.Event) void {
    _ = self;
    switch (event) {
        .char_input => {
            // handle event and store it a compact form in you
        },
        else => {},
    }
}

pub fn recordNwkEvent(self: *Context, event: anytype) void {
    _ = self;
    switch (event) {
        .char_input => {
            // handle event and store it a compact form in you
        },
        else => {},
    }
}

pub fn logic(
    self: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    // conditonal app.switch_context_to = .main_menu;
    _ = self;
    _ = core;
    _ = app;
    _ = gfx;
    _ = snd;
}

pub fn physics(self: *Context) void {
    _ = self;
}
