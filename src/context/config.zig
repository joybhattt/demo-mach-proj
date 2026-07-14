pub const Context = struct {
    pub const Union: type = union(enum(u8)) {
        main_menu: @import("main_menu.zig"),
        dummy: @import("dummy.zig"),
    };

    pub const Enum: type = @typeInfo(Union).@"union".tag_type.?;

    pub const entry_point: Enum = .main_menu;
};
