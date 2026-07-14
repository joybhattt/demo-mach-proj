const mach = @import("root").mach;
const std = @import("std");

// logic, physics and Io thread
pub const App = struct {
    pub const Hz: i64 = 140;
    pub const frame_us: i64 = std.time.us_per_s / Hz;
};

pub const Window = struct {
    pub const title: [:0]const u8 = "Window Title";
    pub const height: u32 = 800;
    pub const width: u32 = 800;
    pub const transparent: bool = false;
    pub const vsync_mode: mach.Core.VSyncMode = .double;
};