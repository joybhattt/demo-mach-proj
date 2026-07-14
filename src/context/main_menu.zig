const std = @import("std");
const mach = @import("root").mach;
const gpu = mach.sysgpu.sysgpu;
const Core = mach.Core;
const Mod = mach.Mod;

const Gfx = @import("../gfx.zig");
const Sound = @import("../sound.zig");
const App = @import("../app.zig");

const Self = @This();

is_open: bool,
key_press: ?Core.KeyButtonID,

pub fn init(self: *Self, _: *Core, _: *App, _: *Gfx, _: *Sound,) void {
    self.* = undefined;
    self.is_open = true;
    self.key_press = null;
}

pub fn recordInputEvent(self: *Self, event: Core.Event) void {
    switch (event) {
        .key_press => |data| {
            switch (data.key) {
                .r, .g, .b => |key| {
                    self.key_press = key;
                },
                .q => {
                    self.is_open = false;
                },
                else => {},
            }
        },
        else => {},
    }
}

pub fn logic(self: *Self, core: *Core, _: *App, gfx: *Gfx, _: *Sound) void {
    if(!self.is_open) core.exit();
    if(self.key_press) |key| {
        gfx.color_mutex.lock(core.io) catch unreachable;
        defer gfx.color_mutex.unlock(core.io);
        gfx.color_attach.clear_value = switch (key) {
            .r => gpu.Color{.a = 1, .r = 1, .g = 0, .b = 0},
            .b => gpu.Color{.a = 1, .r = 0, .g = 0, .b = 1},
            .g => gpu.Color{.a = 1, .r = 0, .g = 1, .b = 0},
            else => unreachable,
        };
    }
}