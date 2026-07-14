
pub fn ThreeDimensional(comptime T: type) type {
    return extern struct {
        const Self = @This();

        x: T = 0x00,
        y: T = 0x00,
        z: T = 0x00,

        const V3 = @Vector(3, T);

        inline fn vector(self: *const Self) V3 {
            return @bitCast(self.*);
        }

        inline fn validate(other: anytype) void {
            const other_type = @TypeOf(other);
            if ( other_type != Self or other_type != T) 
                @compileError("can only add other vector or scalars of same types");
        }

        pub inline fn fill(self: *Self, value: T) Self {
            self.* = @bitCast(V3{value, value, value});
        }

        pub fn cross(self: *const Self, other: *const Self) Self {
            const cyclic = V3{ self.y, self.z, self.x } * V3{ other.z, other.x, other.y };
            const anti_cyclic = V3{ self.z, self.x, self.y } * V3{ other.y, other.z, other.x };
            const cross_product = cyclic - anti_cyclic;
            return @bitCast(cross_product);
        }

        pub inline fn dot(self: *const Self, other: anytype) type {
            comptime validate(other);
            comptime if ( @TypeOf(other) == Self ) {
                return @reduce(.Add, self.vector() * other.vector());
            } else {
                return self.vector() * @as(V3, @splat(other));
            };
        }

        pub inline fn add(self: *const Self, other: anytype) Self {
            comptime validate(other);
            comptime if ( @TypeOf(other) == Self ) {
                return self.vector() + other.vector();
            } else {
                return self.vector() + @as(V3, @splat(other));
            };
        }

        pub inline fn substract(self: *const Self, other: anytype) Self {
            comptime validate(other);
            comptime if ( @TypeOf(other) == Self ) {
                return self.vector() - other.vector();
            } else {
                return self.vector() - @as(V3, @splat(other));
            };        
        }

        pub inline fn divide(self: *const Self, other: anytype) Self {
            comptime validate(other);
            comptime if ( @TypeOf(other) == Self ) {
                return self.vector() / other.vector();
            } else {
                return self.vector() / @as(V3, @splat(other));
            };
        }

        pub inline fn magnitudeSqrd(self: *const Self) T {
            return @bitCast(@reduce(.Add, self.vector() * self.vector()));
        }

        pub inline fn direction(self: *const Self) Self {
            return self.divide(@sqrt(self.magnitudeSqrd()));
        }
    };
}