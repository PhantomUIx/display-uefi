pub fn import(comptime phantom: type) type {
    return struct {
        pub const display = @import("phantom/display.zig").import(phantom);
    };
}
