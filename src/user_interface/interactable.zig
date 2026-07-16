const cln = @import("root").mach.math.collision;

pub fn Interactable(comptime EnumType: type) type {
    return struct {
        pub const InteractionState = struct {
            active: bool = false,
            start: bool = false,
            end: bool = false,

            fn update(self: *InteractionState, is_currently_true: bool) void {
                const was_true = self.active;
                self.active = is_currently_true;
                self.start = is_currently_true and !was_true;
                self.end = !is_currently_true and was_true;
            }
        };

        hover: InteractionState = .{},
        press: InteractionState = .{},
        type: EnumType = undefined,
        hitbox: cln.Rectangle = undefined,

        pub fn init(btn_type: EnumType, center_x: f32, center_y: f32, width: f32, height: f32) @This() {
            var ret_val: Interactable(EnumType) = .{};
            ret_val.type = btn_type;
            ret_val.hitbox = .{
                .pos = .{ .v = .{ center_x - width / 2, center_y - width / 2 } },
                .size = .{ .v = .{ width, height } },
            };
            return ret_val;
        }

        pub fn update(self: *@This(), cursor: *const cln.Point, is_down: bool) void {
            const is_hovering = cursor.collidesRect(self.hitbox);

            self.hover.update(is_hovering);

            // Only allow pressing if we are hovering, otherwise we force un-press
            const is_pressing = is_hovering and is_down;
            self.press.update(is_pressing);
        }
    };
}