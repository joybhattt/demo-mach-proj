const std = @import("std");
const Io = std.Io;

const mach = @import("root").mach;
const gpu = mach.sysgpu.sysgpu;
const Core = mach.Core;
const Mod = mach.Mod;

const Gfx = @import("../gfx.zig");
const Sound = @import("../sound.zig");
const App = @import("../app.zig");

const Self = @This();

pub fn processInputEvent(event: Core.Event, gfx: *Gfx, io: Io, core: *Core) void {
    switch (event) {
        .key_press => |data| {
            switch (data.key) {
                .r, .g, .b => |key| {
                    gfx.color_mutex.lock(io) catch unreachable;
                    defer gfx.color_mutex.unlock(io);
                    gfx.color_attach.clear_value = switch (key) {
                        .r => gpu.Color{ .a = 1, .r = 1, .g = 0, .b = 0 },
                        .b => gpu.Color{ .a = 1, .r = 0, .g = 0, .b = 1 },
                        .g => gpu.Color{ .a = 1, .r = 0, .g = 1, .b = 0 },
                        else => unreachable,
                    };
                },
                .q => { core.exit(); },
                else => {},
            }
        },
        .close => core.exit(),
        else => {},
    }
}
