const std = @import("std");
const os_tag = @import("builtin").target.os.tag;

const win32 = if (os_tag == .windows) struct {
    pub extern "winmm" fn timeBeginPeriod(period: u32) callconv(.c) u32;
    pub extern "winmm" fn timeEndPeriod(period: u32) callconv(.c) u32;
} else struct {};

pub fn precise(io: std.Io, duration: std.Io.Duration, clock: std.Io.Clock) !void {
    switch (comptime os_tag) {
        .windows => {
            _ = win32.timeBeginPeriod(1);
            try io.sleep(duration, clock);
            _ = win32.timeEndPeriod(1);
        },
        else => {
            try io.sleep(duration, clock);
        },
    }
}

pub fn ThreadedTicker(comptime frame_ns: comptime_int) type {
    std.debug.assert(frame_ns > 0);
    return struct {
        const Self = @This();

        // Member fields for an instantiable object
        state: std.atomic.Value(u32) = .init(0),
        thread: ?std.Io.Future(void) = null,
        is_prog_alive: std.atomic.Value(bool) = .init(true),

        pub fn init(self: *Self, io: std.Io) !void {
            if (self.thread) |_| return;
            self.thread = try io.concurrent(mainThread, .{self});
        }

        pub fn deinit(self: *Self, io: std.Io) void {
            if (self.thread) |*thrd| {
                self.is_prog_alive.store(false, .release);
                io.futexWake(@TypeOf(self.state), &self.state, std.math.maxInt(u32));
                _ = thrd.await(io);
                self.thread = null;
            }
        }

        pub fn awaitTick(self: *Self, io: std.Io) !void {
            const current = self.state.load(.acquire);
            while (self.state.load(.acquire) == current) {
                try io.futexWait(@TypeOf(self.state), &self.state, @bitCast(current));
            }
        }

        fn mainThread(self: *Self) void {
            var io_impl = std.Io.Threaded.init_single_threaded;
            defer io_impl.deinit();
            const io = io_impl.io();

            while (self.is_prog_alive.load(.acquire)) {
                precise(io, .fromNanoseconds(frame_ns * 95 / 100), .real) catch {};

                _ = self.state.fetchAdd(1, .release);
                io.futexWake(@TypeOf(self.state), &self.state, std.math.maxInt(u32));
            }
        }
    };
}
