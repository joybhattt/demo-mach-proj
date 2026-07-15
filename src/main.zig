const std = @import("std");
const mach = @import("root").mach;

pub const Modules = @import("root").config.Main.mach_modules;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var io_threaded = std.Io.Threaded.init(allocator, .{});
    const io = io_threaded.io();

    var mods: Modules = undefined;
    try mods.init(allocator, io);
    // TODO: enable mods.deinit(allocator); for allocator leak detection
    // defer mods.deinit(allocator);

    const app_mod = mods.get(.app);
    app_mod.call(.main);
}
