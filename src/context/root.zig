pub const Dummy = @import("dummy.zig");
pub const MainMenu = @import("main_menu.zig");

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const config = @import("root").config;

const mach = @import("root").mach;
const Core = mach.Core;
const Mod = mach.Mod;

pub const Context = @This();
const Gfx = @import("root").Gfx;
const Sound = @import("root").Sound;
const App = @import("root").App;

pub const mach_module = .context;
pub const mach_systems = .{
    .init,
    .deinit,
    .pollInputEvents,
    .fetchNetEvents,
    .process,
};

pub const process = schedule_blk: {
    const mods_tuple = config.Context.all_modules;
    const len = @typeInfo(@TypeOf(mods_tuple)).@"struct".fields.len;
    var entries_type: [len]type = undefined;
    for (0..len) |ii| {
        entries_type[ii] = @TypeOf(.{ mods_tuple[ii], .process });
    }
    var entries_tuple: std.meta.Tuple(&entries_type) = undefined;
    for (0..len) |ii| {
        entries_tuple[ii] = .{ mods_tuple[ii], .process };
    }
    break :schedule_blk mach.schedule(entries_tuple);
};

/// place holders
const Net = struct {
    const Event = struct {};
};

input_events: []const Core.Event,
nwk_events: []const Core.Event, 

active: enum_blk: {
    const mods_tuple = config.Context.all_modules;
    const len = @typeInfo(@TypeOf(mods_tuple)).@"struct".fields.len;
    var field_names: [len][]const u8 = undefined;
    const BitWidth = std.math.log2_int_ceil(usize, len);
    const BackingType = std.meta.Int(.unsigned, BitWidth);
    var field_values: [len]BackingType = undefined;
    for (0..len) |ii| {
        const mod = mods_tuple[ii];
        if (!@hasDecl(mod, "mach_module")) {
            @compileError("Type is missing 'pub const mach_module' declaration!");
        }
        field_names[ii] = @tagName(mod.mach_module);
        field_values[ii] = @intCast(ii);
    }
    break :enum_blk @Enum(BackingType, .exhaustive, &field_names, &field_values);
},

pub fn init(
    ctx: *Context,
    entry_ctx_mod: Mod(config.Context.entry_point),
) !void {
    ctx.* = .{
        .events = .{
            .input = &.{},
            .network = &.{},
        },
        .active = config.Context.entry_point.mach_module,
    };
    entry_ctx_mod.call(.init);
}

pub fn deinit(
    ctx: *Context,
) void {
    _ = ctx;
}

pub fn pollInputEvents(
    ctx: *Context,
    core: *Core,
) void {
    ctx.events.input = core.events(.default).events;
}

// NO net implementations yet
pub fn fetchNetEvents(
    ctx: *Context,
) void {
    _ = ctx;
}
