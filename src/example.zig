const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");
const phantom = @import("phantom");
const vizops = @import("vizops");

pub const phantomOptions = struct {
    pub const displayBackends = struct {
        pub const uefi = @import("phantom.display.uefi").display.backends.uefi;
    };
};

const displayBackend = phantom.display.Backend(.uefi);

const sceneBackendType: phantom.scene.BackendType = @enumFromInt(@intFromEnum(options.scene_backend));
const sceneBackend = phantom.scene.Backend(sceneBackendType);

pub fn main() void {
    const alloc = if (builtin.link_libc) std.heap.c_allocator else if (builtin.os.tag == .uefi) std.os.uefi.pool_allocator else std.heap.page_allocator;

    var display = displayBackend.Display.init(alloc, .compositor);
    defer display.deinit();

    const outputs = @constCast(&display.display()).outputs() catch |e| @panic(@errorName(e));
    defer outputs.deinit();

    if (outputs.items.len == 0) {
        @panic("No outputs");
    }

    const output = outputs.items[0];
    const surface = output.createSurface(.output, .{
        .size = (output.info() catch |e| @panic(@errorName(e))).size.res,
    }) catch |e| @panic(@errorName(e));
    defer {
        surface.destroy() catch {};
        surface.deinit();
    }

    const scene = surface.createScene(@enumFromInt(@intFromEnum(sceneBackendType))) catch |e| @panic(@errorName(e));
    _ = scene;
    // TODO: render something to the scene
}
