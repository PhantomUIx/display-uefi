pub fn import(comptime phantom: type) type {
    return struct {
        pub const Display = @import("uefi/display.zig").import(phantom);
        pub const Output = @import("uefi/output.zig").import(phantom);
        pub const Surface = @import("uefi/surface.zig").import(phantom);
    };
}
