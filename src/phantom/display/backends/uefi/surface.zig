const std = @import("std");
const phantom = @import("phantom");
const Output = @import("output.zig");
const Self = @This();

base: phantom.display.Surface,
output: *Output,

pub fn new(output: *Output) !*Self {
    const self = try output.display.allocator.create(Self);
    errdefer output.display.allocator.destroy(self);

    self.* = .{
        .base = .{
            .ptr = self,
            .vtable = &.{
                .deinit = impl_deinit,
                .destroy = impl_destroy,
                .info = impl_info,
                .updateInfo = impl_update_info,
                .createScene = impl_create_scene,
            },
            .displayKind = output.base.displayKind,
            .kind = .output,
            .type = @typeName(Self),
        },
        .output = output,
    };
    return self;
}

fn impl_deinit(ctx: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.output.display.allocator.destroy(self);
}

fn impl_destroy(_: *anyopaque) anyerror!void {
    return error.CannotDestroy;
}

fn impl_info(ctx: *anyopaque) anyerror!phantom.display.Surface.Info {
    const self: *Self = @ptrCast(@alignCast(ctx));
    const outputInfo = try self.output.base.info();
    return .{
        .format = outputInfo.format,
        .size = outputInfo.size.res,
        .maxSize = outputInfo.size.res,
        .minSize = outputInfo.size.res,
    };
}

fn impl_update_info(ctx: *anyopaque, info: phantom.display.Surface.Info, fields: []std.meta.FieldEnum(phantom.display.Surface.Info)) anyerror!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    var outputFields = std.ArrayList(std.meta.FieldEnum(phantom.display.Output.Info)).init(self.output.display.allocator);
    defer outputFields.deinit();

    const outputInfo = try self.output.base.info();

    for (fields) |field| {
        switch (field) {
            .size => try outputFields.append(.size),
            .format => try outputFields.append(.format),
            else => return error.UnsupportedField,
        }
    }

    return self.output.base.updateInfo(.{
        .scale = outputInfo.scale,
        .format = info.format orelse outputInfo.format,
        .size = .{
            .phys = info.size.cast(f32),
            .res = info.size,
        },
    }, outputFields.items);
}

fn impl_create_scene(ctx: *anyopaque, backendType: phantom.scene.BackendType) anyerror!*phantom.scene.Base {
    _ = ctx;
    _ = backendType;
    return error.NotImplemented;
}
