const mach = @import("root").mach;
const Core = mach.Core;
const Mod = mach.Mod;

const Context = @This();
const Gfx = @import("root").Gfx;
const Sound = @import("root").Sound;
const App = @import("root").App;

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

pub fn processInputEvent(self: *Context, event: Core.Event) void {
    _ = self;
    switch (event) {
        .char_input => {
            // handle event or store it a compact form
        },
        else => {},
    }
}

pub fn processNwkEvent(self: *Context, event: anytype) void {
    _ = self;
    switch (event) {
        .char_input => {
            // handle event or store it a compact form
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
    // conditonal app.switch_context_to = .another_contex;
    _ = self;
    _ = core;
    _ = app;
    _ = gfx;
    _ = snd;
}

pub fn physics(self: *Context) void {
    _ = self;
}
