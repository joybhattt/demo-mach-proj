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

// module specific aliases

const math = mach.math;
const cln = math.collision;

const Gfx = @import("root").Gfx;
const App = @import("root").App;
const MainMenu = @This();

const config = @import("root").config;

pub const mach_module = .main_menu;
pub const mach_systems = .{ .init, .process, .input, .updates, .logic, .deinit, .updateButtons, .processButtons };

/// the buttons will likely have more descriptive names
const ButtonSet = enum {
    button0,
    button1,
    button2,
};

/// create a interactable class from the set
const Button = @import("root").ui.Interactable(ButtonSet);

buttons: mach.Objects(.{}, Button),
mouse_down: bool,
mouse_pos: Core.Position,

pub fn init(mmenu: *MainMenu) !void {
    mmenu.* = .{
        .mouse_down = false,
        .mouse_pos = .{ .x = 0, .y = 0 }, // out of bound init
        .buttons = mmenu.buttons,
    };

    // init buttons
    // note the order of init is not button0 button1 button2
    // this is because the order of init here decides the priority of buttons
    // that is if button1 and button0 both had the same interaction state then the priority will be
    // given to the one initialized first.
    // it is important that all buttons be inited at the start any deletions and lazy new buttons will
    // mess the priority due to mach.Objects internal recycling mechanic
    _ = try mmenu.buttons.new(Button.init(.button1, -10, -10, 1, 1)); // offscreen
    _ = try mmenu.buttons.new(Button.init(.button0, 400, 400, 10, 10)); //dead center of window
    _ = try mmenu.buttons.new(Button.init(.button2, -10, -10, 1, 1)); // offscreen
}

pub fn deinit(mmenu: *MainMenu) void {
    // clean the buttons
    var slice = mmenu.buttons.slice();
    while (slice.next()) |id| mmenu.buttons.delete(id);
}

pub fn process(app: *App, mmenu_mod: Mod(MainMenu)) void {
    if (app.current_context != .main_menu) return;
    mmenu_mod.call(.input);
    mmenu_mod.call(.updates);
    mmenu_mod.call(.logic);
}

pub fn input(
    mmenu: *MainMenu,
    core: *Core,
) void {
    // collect one frame worth of compact input
    var events = core.events(.default);
    while (events.next()) |*event| {
        switch (event.*) {
            .mouse_motion => |*data| {
                mmenu.mouse_pos = data.pos;
            },
            .mouse_press => |*data| {
                mmenu.mouse_pos = data.pos;
                if (data.button == .left) mmenu.mouse_down = true;
            },
            .mouse_release => |*data| {
                mmenu.mouse_pos = data.pos;
                if (data.button == .left) mmenu.mouse_down = false;
            },
            .close => core.exit(),
            else => {},
        }
    }
}

pub fn updates(mmenu_mod: Mod(MainMenu)) void {
    mmenu_mod.call(.updateButtons);
    // other updates like physics
}

pub fn logic(mmenu_mod: Mod(MainMenu)) void {
    mmenu_mod.call(.processButtons);
    // other logic like game mechanics
}

pub fn updateButtons(
    mmenu: *MainMenu,
) void {
    const cursor: cln.Point = .{ .pos = .{ .v = .{
        @floatCast(mmenu.mouse_pos.x),
        @floatCast(mmenu.mouse_pos.y),
    } } };
    const is_down = mmenu.mouse_down;

    var slice = mmenu.buttons.slice();
    while (slice.next()) |id| {
        var btn = mmenu.buttons.getValue(id);
        btn.update(&cursor, is_down);
        mmenu.buttons.setValue(id, btn);
    }
}

/// one function that defines the callbacks of all the button types
pub fn processButtons(mmenu: *MainMenu) void {
    var slice = mmenu.buttons.slice();
    while (slice.next()) |id| {
        const btn = mmenu.buttons.getValue(id);

        // note priority is the order in which they are processed from the slice
        // and not the enum type of them
        // priority does not mean that only the most eligible callback is fired
        // it means the most elligible callback is fired first
        // and since all callbacks are in the same function the first callback can
        // return the function negating all low priority callbacks
        switch (btn.type) {
            .button0 => { // define callbacks for button0
                if (btn.hover.start) print("button0 has the cursor focus\n", .{});
                if (btn.hover.end) print("button0 lost the cursor focus\n", .{});
                if (btn.hover.active) print("this message will print repeatedly while the cursor is above the button0\n", .{});

                if (btn.press.start) print("button0 is clicked\n", .{});
                if (btn.press.end) print("button0 was released\n", .{});
                if (btn.press.active) print("this msg will print repeatedly while button0 is pressed down\n", .{});
            },
            .button1 => {
                // cbs for button1
            },
            .button2 => {
                // cbs for button2
            },
            // note the use of enum makes it so you can ignore ceratain callbacks by else and can
            // have multi switches based on modes so ui elements are not even evaluated if needed
        }
    }
}
