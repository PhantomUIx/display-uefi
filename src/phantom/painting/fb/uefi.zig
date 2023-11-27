const std = @import("std");
const vizops = @import("vizops");
const phantom = @import("phantom");
const Surface = @import("../../display/backends/uefi/surface.zig");
const Self = @This();

base: phantom.painting.fb.Base,
surface: *Surface,

pub fn new(surface: *Surface) !*Self {
    const self = try surface.output.display.allocator.create(Self);
    errdefer surface.output.display.allocator.destroy(self);

    self.* = .{
        .base = .{
            .allocator = surface.output.display.allocator,
            .vtable = &.{
                .addr = impl_addr,
                .info = impl_info,
                .dupe = impl_dupe,
                .deinit = impl_deinit,
                .blt = null,
            },
            .ptr = self,
        },
        .surface = surface,
    };
    return self;
}

fn impl_addr(ctx: *anyopaque) anyerror!*anyopaque {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return @ptrFromInt(self.surface.output.protocol.mode.frame_buffer_base);
}

fn impl_info(ctx: *anyopaque) phantom.painting.fb.Base.Info {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const info = self.surface.output.base.info() catch |e| @panic(@errorName(e));
    return .{
        .res = info.size.res,
        .colorFormat = info.colorFormat,
        .colorspace = .sRGB,
    };
}

fn impl_dupe(ctx: *anyopaque) anyerror!*phantom.painting.fb.Base {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return &(try new(self.surface)).base;
}

fn impl_deinit(ctx: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.surface.output.display.allocator.destroy(self);
}
