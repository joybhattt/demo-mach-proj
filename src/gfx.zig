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

const gpu = mach.sysgpu.sysgpu;
const config = @import("config.zig");
const util = @import("root").util;

pub const Gfx = @This();
const App = @import("root").App;

pub const mach_module = .gfx;
pub const mach_systems = .{
    .init,
    .snapshot,
    .on_render,
    .deinit,
    .load,
    .process,
};

pub const process = mach.schedule(.{
    .{ Core, .snapshotStart },
    .{ Gfx, .snapshot },
    .{ Core, .snapshotEnd },
});

window_id: ObjID,

color_attach: gpu.RenderPassColorAttachment,
rpass_desc: gpu.RenderPassDescriptor,

pub fn init(
    gfx: *Gfx,
    app: *App,
) !void {
    gfx.* = undefined;
    gfx.window_id = app.window_id;

    gfx.color_attach = .{
        .clear_value = .{ .a = 1, .r = 1, .b = 1, .g = 1 },
        .load_op = .clear,
        .store_op = .store,
        .next_in_chain = .{ .generic = null },
        .resolve_target = null,
        .view = null,
    };

    gfx.rpass_desc = .{
        .label = "[[RenderPass]]",
        .next_in_chain = .{ .generic = null },
        .color_attachment_count = 1,
        .color_attachments = @ptrCast(&gfx.color_attach),
        .depth_stencil_attachment = null,
        .occlusion_query_set = null,
        .timestamp_write_count = 0,
        .timestamp_writes = null,
    };
}

pub fn deinit() void {}

pub fn load() void {}

pub fn on_render(core: *Core, gfx: *Gfx) !void {
    const current_view = core.windows.get(gfx.window_id, .swap_chain).getCurrentTextureView() orelse {
        return;
    };
    defer current_view.release();
    gfx.color_attach.view = current_view;

    const encoder = core.windows.get(gfx.window_id, .device).createCommandEncoder(null);
    defer encoder.release();

    const rpass = encoder.beginRenderPass(&gfx.rpass_desc);
    defer rpass.release();

    rpass.end();

    const command = encoder.finish(null);
    defer command.release();

    core.windows.get(gfx.window_id, .queue).submit(&.{command});
}

pub fn snapshot() void {
    // if any change should be made to the offscreen framebuffer
    // all the render pass should be submitted into the same queue submit for
    // making sure we dont have the frame being rendered with few and not all renderpasses
}
