const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

pub fn AtomicSynced(comptime T: type) type {
    return extern struct {
        barrier: std.atomic.Value(u16) align(64) = .init(0),
        prev: u16 = std.math.maxInt(u16),
        payload: T,

        threadlocal var role: if (builtin.mode == .Debug)
            enum(u8) {
                undefined,
                reader,
                writer,
            }
        else
            void = if (builtin.mode == .Debug)
            .undefined
        else {};

        fn assertRole(thread_role: @TypeOf(role)) void {
            if (builtin.mode == .Debug) {
                if (role == .undefined)
                    setRole(.reader);
                assert(role == thread_role);
            }
        }

        fn setRole(thread_role: @TypeOf(role)) void {
            if (builtin.mode == .Debug) {
                role = thread_role;
            }
        }

        pub fn aquire(self: *@This()) ?*const T {
            assertRole(.reader);
            const current: u16 = self.barrier.load(.acquire);
            const prev = self.prev;
            self.prev = current;
            if (current != prev) return &self.payload;
            return null;
        }

        pub fn release(self: *@This(), value: *T) void {
            assertRole(.writer);
            @memcpy(self.payload, value);
            _ = self.barrier.fetchAdd(1, .release);
        }

        pub fn init(value: T) @This() {
            assertRole(.undefined);
            setRole(.writer);
            return .{ .payload = value };
        }

        pub fn getPtr(self: *@This()) *T {
            assertRole(.writer);
            return &self.payload;
        }
    };
}