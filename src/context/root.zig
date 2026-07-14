// const std = @import("std");
// const assert = std.debug.assert;

// const config = @import("root").config;

// const mach = @import("root").mach;
// const Core = mach.Core;
// const Mod = mach.Mod;

// const Context = @This();
// const Gfx = @import("../gfx.zig");
// const Sound = @import("../sound.zig");
// const App = @import("../app.zig");

// pub const mach_module = .context;
// pub const mach_systems = .{
//     .init,
//     .deinit,
//     .pollInputEvents,
//     .fetchNetEvents,
//     .process,
//     .processSwitch,
//     .physics,
//     .logic,
// };

// pub const process = mach.schedule(.{
//     .{ Context, .physics },
//     .{ Context, .logic },
//     .{ Context, .processSwitch },
// });

// union_ctx: config.Context.Union,

// pub fn init(ctx: *Context) !void {
//     ctx.* = undefined;

//     ctx.union_ctx = @unionInit(
//         config.Context.Union,
//         @tagName(config.Context.entry_point),
//         undefined,
//     );
// }

// pub fn deinit(
//     ctx: *Context,
//     core: *Core,
//     app: *App,
//     gfx: *Gfx,
//     snd: *Sound,
// ) void {

//     switch (ctx.union_ctx) {
//         inline else => |*context| {
//             if (@hasDecl(@TypeOf(context.*), "deinit")) context.deinit(core, app, gfx, snd);
//         },
//     }
// }

// pub fn processSwitch(
//     ctx: *Context,
//     ctx_mod: Mod(Context),
//     core: *Core,
//     app: *App,
//     gfx: *Gfx,
//     snd: *Sound,
// ) void {
//     const ctx_tag = app.switch_context_to orelse return;
//     if (ctx_tag == std.meta.activeTag(ctx.union_ctx)) return;

//     ctx_mod.run(.deinit);

//     switch (ctx_tag) {
//         inline else => |tag| {
//             ctx.union_ctx = @unionInit(
//                 config.Context.Union,
//                 @tagName(tag),
//                 undefined,
//             );
//         },
//     }
//     switch (ctx.union_ctx) {
//         inline else => |*context| {
//             context.init(core, app, gfx, snd);
//         },
//     }
//     ctx.switch_ctx = null;
// }

// pub fn physics(ctx: *Context) void {
//     switch (ctx.union_ctx) {
//         inline else => |*context| {
//             if (@hasDecl(@TypeOf(context.*), "physics"))
//                 context.physics();
//         },
//     }
// }

// pub fn logic(
//     ctx: *Context,
//     core: *Core,
//     app: *App,
//     gfx: *Gfx,
//     snd: *Sound,
// ) void {
//     switch (ctx.union_ctx) {
//         inline else => |*context| {
//             if (@hasDecl(@TypeOf(context.*), "logic"))
//                 context.logic(core, app, gfx, snd);
//         },
//     }
// }

// pub fn pollInputEvents(ctx: *Context, core: *Core) void {
//     var events = core.events(.default);
//     while (events.next()) |event| switch (ctx.union_ctx) {
//         inline else => |*context| {
//             if (@hasDecl(@TypeOf(context.*), "recordInputEvent"))
//                 context.recordInputEvent(event);
//         },
//     };
// }

// pub fn fetchNetEvents() void {
//     // pub fn fetchNetEvents(ctx: *Context, nwk: anytype) void {
//     //     var events = nwk.events(.default);
//     //     while (events.next()) |event| switch (ctx.union_ctx) {
//     //         inline else => |*context| comptime {
//     //             if (@hasDecl(@TypeOf(context.*), "recordNwkEvent"))
//     //                 context.recordNwkEvent(event);
//     //         },
//     //     };
// }
