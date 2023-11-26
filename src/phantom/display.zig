pub fn import(comptime phantom: type) type {
    return struct {
        pub const backends = @import("display/backends.zig").import(phantom);
    };
}
