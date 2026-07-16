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

const App = @import("root").App;

pub const mach_module = .dummy;
pub const mach_systems = .{.process};

pub fn process(app: *App) void {
    if (app.current_context != .dummy) return;
    print("constext switced to dummy\n", .{});
    defer print("context switched to main_menu\n", .{});
    app.current_context = .main_menu;
}
