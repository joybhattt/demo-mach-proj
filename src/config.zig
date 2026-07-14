const mach = @import("root").mach;
const std = @import("std");

// logic, physics and Io thread
pub const Tick = struct {
    pub const Hz: i64 = 140;
    pub const frame_us: i64 = std.time.us_per_s / Hz;
};

pub const Gfx = struct {
};

pub const Window = struct {
    pub const title: [:0]const u8 = "Window Title";
    pub const height: u32 = 800;
    pub const width: u32 = 800;
    pub const transparent: bool = false;
    pub const vsync_mode: mach.Core.VSyncMode = .double;
};

pub const Context = struct {
    const context = @import("root").context;

    pub const Union: type = union(enum(u8)) {
        main_menu:  context.MainMenu,
        dummy:      context.Dummy,
    };

    pub const Enum: type = @typeInfo(Union).@"union".tag_type.?;

    pub const entry_point: Enum = .main_menu;
};
