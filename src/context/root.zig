pub const Dummy = @import("dummy.zig");
pub const MainMenu = @import("main_menu.zig");

const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const config = @import("config.zig");

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
    .processSwitch,
    .physics,
    .logic,
};

pub const process = mach.schedule(.{
    .{ Context, .physics },
    .{ Context, .logic },
    .{ Context, .processSwitch },
});

union_ctx: config.Context.Union,

pub fn init(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    app: *App,
    snd: *Sound,
    gfx: *Gfx,
) !void {
    ctx.* = undefined;

    ctx.union_ctx = @unionInit(
        config.Context.Union,
        @tagName(config.Context.entry_point),
        undefined,
    );

    switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "init")) {
                const target_fn = @TypeOf(context.*).init;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, allocator });
                @call(.auto, target_fn, args);
            }
        },
    }
}

pub fn deinit(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "deinit")) {
                const target_fn = @TypeOf(context.*).deinit;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, allocator });
                @call(.auto, target_fn, args);
            }
        },
    }
}

pub fn processSwitch(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
    ctx_mod: Mod(Context),
) void {
    const ctx_tag = app.switch_context_to orelse return;
    if (ctx_tag == std.meta.activeTag(ctx.union_ctx)) return;

    ctx_mod.call(.deinit);

    switch (ctx_tag) {
        inline else => |tag| {
            ctx.union_ctx = @unionInit(
                config.Context.Union,
                @tagName(tag),
                undefined,
            );
        },
    }

    switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "init")) {
                const target_fn = @TypeOf(context.*).init;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, allocator });
                @call(.auto, target_fn, args);
            }
        },
    }
}

pub fn physics(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "physics")) {
                const target_fn = @TypeOf(context.*).physics;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, allocator });
                @call(.auto, target_fn, args);
            }
        },
    }
}

pub fn logic(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    app: *App,
    gfx: *Gfx,
    snd: *Sound,
) void {
    switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "logic")) {
                const target_fn = @TypeOf(context.*).logic;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, allocator });
                @call(.auto, target_fn, args);
            }
        },
    }
}

pub fn pollInputEvents(
    io: Io,
    allocator: Allocator,
    ctx: *Context,
    core: *Core,
    gfx: *Gfx,
    app: *App,
    snd: *Sound,
) void {
    var events = core.events(.default);
    while (events.next()) |event| switch (ctx.union_ctx) {
        inline else => |*context| {
            if (@hasDecl(@TypeOf(context.*), "processInputEvent")) {
                const target_fn = @TypeOf(context.*).processInputEvent;
                const args = injectedArgs(target_fn, .{ context, core, gfx, io, app, snd, event, allocator });
                @call(.auto, target_fn, args);
            }
        },
    };
}

// NO net implementations yet
pub fn fetchNetEvents() void {
    // pub fn fetchNetEvents(ctx: *Context, nwk: anytype) void {
    //     var events = nwk.events(.default);
    //     while (events.next()) |event| switch (ctx.union_ctx) {
    //         inline else => |*context| comptime {
    //             if (@hasDecl(@TypeOf(context.*), "processNwkEvent"))
    //                 context.processNwkEvent(event);
    //         },
    //     };
}

fn injectedArgs(comptime function: anytype, args: anytype) std.meta.ArgsTuple(@TypeOf(function)) {
    const params = @typeInfo(@TypeOf(function)).@"fn".params;
    var ret_params: std.meta.ArgsTuple(@TypeOf(function)) = undefined;

    inline for (params, 0..) |param, ii| {
        ret_params[ii] = matchArg(param.type.?, args);
    }

    return ret_params;
}

fn matchArg(comptime arg_type: type, args: anytype) arg_type {
    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;
    inline for (fields) |field| {
        if (field.type == arg_type) {
            return @field(args, field.name);
        }
    }
    @compileError("no available injection for field with type " ++ @typeName(arg_type));
}