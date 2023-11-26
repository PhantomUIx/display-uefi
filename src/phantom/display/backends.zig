pub fn import(comptime phantom: type) type {
    return struct {
        pub const uefi = @import("backends/uefi.zig").import(phantom);
    };
}
