const std = @import("std");
const Io = std.Io;

const mach = @import("root").mach;
const gpu = mach.sysgpu.sysgpu;
const Core = mach.Core;
const Mod = mach.Mod;

const Context = @import("root").Context;

pub const mach_module = .dummy;
pub const mach_systems = .{.process};

pub fn process(ctx: *Context) void {
    if (ctx.active != .dummy) return;
    std.debug.print("switced to dummy\n", .{});
    ctx.active = .main_menu;
}
