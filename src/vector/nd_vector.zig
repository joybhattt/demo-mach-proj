const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");

pub fn Ndimensional(comptime Type: type) type {
    return struct {
        data: []Type,
        comptime T: type = Type,
        comptime vec_len: usize = std.simd.suggestVectorLength(Type) orelse 128 / @bitSizeOf(Type),
        comptime Vector: type = @Vector(std.simd.suggestVectorLength(Type) orelse 128 / @bitSizeOf(Type), Type),
        const Self = @This();

        const is_Ndimensional: void = {};
        inline fn vec(self: *Self, start: usize, comptime vec_len: usize) @Vector(vec_len, self.T) {
            return self.data[start .. start + vec_len][0..vec_len].*;
        }

        pub inline fn len(self: *Self) usize {
            return self.data.len;
        }

        pub inline fn create(allocator: std.mem.Allocator, length: usize) error{OutOfMemory}!Self {
            return .{ .data = try allocator.alloc(Type, length) };
        }

        pub inline fn copy(self: *Self, allocator: std.mem.Allocator) error{OutOfMemory}!Self {
            const new_vector = try create(allocator, self.len());
            @memcpy(new_vector.data, self.data);
            return new_vector;
        }

        pub inline fn destroy(self: *Self, allocator: std.mem.Allocator) void {
            if (self.data.len != 0) {
                allocator.free(self.data);
                self.data.len = 0;
            }
        }

        pub inline fn fill(self: *Self, value: self.T) void {
            @memset(self.data, value);
        }

        fn validateResult(result: anytype) void {
            const PtrInfo = @typeInfo(@TypeOf(result));
            if (PtrInfo != .pointer or (!@hasDecl(PtrInfo.pointer.child, "is_Ndimensional")))
                @compileError("result_nd must be a *Ndimensional");
        }

        fn validateOther(other: anytype) void {
            const PtrInfo = @typeInfo(@TypeOf(other));
            if (PtrInfo != .pointer or (!@hasDecl(PtrInfo.pointer.child, "is_Ndimensional")))
                @compileError("other_nd must be a *Ndimensional");
        }

        pub fn operateTo(
            self: *Self,
            result_nd: anytype,
            operation_fn: anytype,
            args: anytype,
            start_ii: usize,
            end_ii: usize,
        ) void {
            const result = result_nd;
            validateResult(result);
            std.debug.assert(result.len() >= end_ii and self.len() >= end_ii);
            std.debug.assert(@TypeOf(
                @call(
                    .auto,
                    operation_fn,
                    .{self.vec(0, 1)} ++ args,
                ),
            ) == @Vector(1, result.T));

            const vec_len = @min(self.vec_len, result.vec_len);
            const total_elements = end_ii - start_ii;
            const loops = (total_elements) / vec_len;
            const remainder_start = loops * vec_len + start_ii;

            for (0..loops) |i| {
                const current_idx = start_ii + (i * vec_len);

                // Load unaligned data into vectors on the fly
                const v_a: @Vector(vec_len, Type) = self.data[current_idx..][0..vec_len].*;

                const v_res = @call(
                    .auto,
                    operation_fn,
                    .{v_a} ++ args,
                );

                // Store back safely
                result_nd.data[current_idx..][0..vec_len].* = v_res;
            }

            // Scalar remainder loop
            for (remainder_start..end_ii) |ii| {
                const val = @call(
                    .auto,
                    operation_fn,
                    .{ self.vec(ii, 1), result.vec(ii, 1) } ++ args,
                );
                result_nd.data[ii] = val[0];
            }
        }

        pub fn operateWithTo(
            self: *Self,
            other_nd: anytype,
            result_nd: anytype,
            operation_fn: anytype,
            args: anytype,
            start_ii: usize,
            end_ii: usize,
        ) void {
            validateOther(other_nd);
            validateResult(result_nd);
            const result = result_nd;
            const other = other_nd;

            std.debug.assert(self.len() >= end_ii and result.len() >= end_ii and self.len() >= end_ii);
            std.debug.assert(@TypeOf(
                @call(
                    .auto,
                    operation_fn,
                    .{
                        self.vec(0, 1),
                        other.vec(0, 1),
                    } ++ args,
                ),
            ) == @Vector(1, result.T));

            const vec_len = @min(self.vec_len, result.vec_len);
            const loops = (end_ii - start_ii) / vec_len;
            const remainder_start = loops * vec_len + start_ii;

            // Correctly cast and assert the alignment for SIMD operations
            for (0..loops) |ii| {
                const current_idx = start_ii + (ii * vec_len);

                // Load slice data directly into vectors on the stack
                const v_a: @Vector(vec_len, Type) = self.data[current_idx..][0..vec_len].*;
                const v_b: @Vector(vec_len, Type) = other.data[current_idx..][0..vec_len].*;

                // Explicitly typing this variable forces a compilation error
                // if operation_fn returns an incorrect type or size.
                const v_res: @Vector(vec_len, result.T) = @call(
                    .auto,
                    operation_fn,
                    .{ v_a, v_b } ++ args,
                );

                // Store back safely without needing strict pointer alignment
                result.data[current_idx..][0..vec_len].* = v_res;
            }

            for (remainder_start..end_ii) |ii| {
                const val: @Vector(1, result.T) = @call(
                    .auto,
                    operation_fn,
                    .{
                        (self.vec(ii, 1)),
                        (other.vec(ii, 1)),
                    } ++ args,
                );
                result.data[ii] = val[0];
            }
        }

        pub inline fn destroyTo(
            self: *Self,
            allocator: std.mem.Allocator,
            initial: anytype,
            reduce_op: std.builtin.ReduceOp,
        ) @TypeOf(initial) {
            const reduce_length = self.vec_len - 1;
            const loops = self.data.len / reduce_length;
            const remainder_start = loops * reduce_length;

            switch (reduce_op) {
                .Add => self.data[0] += initial,
                .Mul => self.data[0] *= initial,
                .Max => self.data[0] = @max(initial, self.data[0]),
                .Min => self.data[0] = @min(initial, self.data[0]),
                .And => self.data[0] = self.data[0] and initial,
                .Or => self.data[0] = self.data[0] or initial,
                .Xor => self.data[0] = self.data[0] != initial,
            }

            for (0..loops) |ii| {
                const start = ii * reduce_length; // start_index
                const end = start + self.vec_len; // end_index

                self.data[end - 1] = @reduce(reduce_op, self.vec(start, self.vec_len));
            }

            for (remainder_start..self.data.len - 1) |ii| {
                switch (reduce_op) {
                    .Add => self.data[ii + 1] += self.data[ii],
                    .Mul => self.data[ii + 1] *= self.data[ii],
                    .Max => self.data[ii + 1] = @max(self.data[ii], self.data[ii + 1]),
                    .Min => self.data[ii + 1] = @min(self.data[ii], self.data[ii + 1]),
                    .And => self.data[ii + 1] = self.data[ii + 1] and self.data[ii],
                    .Or => self.data[ii + 1] = self.data[ii + 1] or self.data[ii],
                    .Xor => self.data[ii + 1] = self.data[ii + 1] != self.data[ii],
                }
            }
            const return_val = self.data[self.data.len - 1];
            self.destroy(allocator);
            return return_val;
        }
    };
}


