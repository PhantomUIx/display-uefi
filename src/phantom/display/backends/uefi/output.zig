const std = @import("std");
const vizops = @import("vizops");
const phantom = @import("phantom");
const Display = @import("display.zig");
const Surface = @import("surface.zig");
const Self = @This();

base: phantom.display.Output,
display: *Display,
protocol: *std.os.uefi.protocol.GraphicsOutput,
surface: ?*Surface,
scale: vizops.vector.Float32Vector2,

pub fn new(display: *Display, protocol: *std.os.uefi.protocol.GraphicsOutput) !*Self {
    const self = try display.allocator.create(Self);
    errdefer display.allocator.destroy(self);

    self.* = .{
        .base = .{
            .ptr = self,
            .vtable = &.{
                .surfaces = impl_surfaces,
                .createSurface = impl_create_surface,
                .info = impl_info,
                .updateInfo = impl_update_info,
                .deinit = impl_deinit,
            },
            .displayKind = display.kind,
            .type = @typeName(Self),
        },
        .display = display,
        .protocol = protocol,
        .surface = null,
        .scale = vizops.vector.Float32Vector2.init(1.0),
    };
    return self;
}

fn infoFromMode(self: *Self, info: *std.os.uefi.protocol.GraphicsOutput.Mode.Info) !phantom.display.Output.Info {
    const res = vizops.vector.UsizeVector2.init([_]usize{
        @as(usize, @intCast(info.horizontal_resolution)),
        @as(usize, @intCast(info.vertical_resolution)),
    });

    return .{
        .enable = true,
        .size = .{
            .phys = .{ .value = res.cast(f32).value },
            .res = .{ .value = res.value },
        },
        .scale = .{ .value = self.scale.value },
        .name = "UEFI GOP",
        .manufacturer = "Unknown",
        .colorFormat = switch (info.pixel_format) {
            .RedGreenBlueReserved8BitPerColor => .{
                .rgbx = @splat(8),
            },
            .BlueGreenRedReserved8BitPerColor => .{
                .bgrx = @splat(8),
            },
            else => return error.InvalidPixelFormat,
        },
    };
}

fn impl_surfaces(ctx: *anyopaque) anyerror!std.ArrayList(*phantom.display.Surface) {
    const self: *Self = @ptrCast(@alignCast(ctx));
    var surfaces = std.ArrayList(*phantom.display.Surface).init(self.display.allocator);
    errdefer surfaces.deinit();

    if (self.surface) |surf| {
        try surfaces.append(&surf.base);
    }
    return surfaces;
}

fn impl_create_surface(ctx: *anyopaque, kind: phantom.display.Surface.Kind, _: phantom.display.Surface.Info) anyerror!*phantom.display.Surface {
    const self: *Self = @ptrCast(@alignCast(ctx));

    if (kind != .output) return error.InvalidKind;
    if (self.surface) |_| return error.AlreadyExists;

    self.surface = try Surface.new(self);
    return &self.surface.?.base;
}

fn impl_info(ctx: *anyopaque) anyerror!phantom.display.Output.Info {
    const self: *Self = @ptrCast(@alignCast(ctx));

    var info: *std.os.uefi.protocol.GraphicsOutput.Mode.Info = undefined;
    var info_size: usize = undefined;
    try self.protocol.queryMode(self.protocol.mode.mode, &info_size, &info).err();
    return self.infoFromMode(info);
}

fn impl_update_info(ctx: *anyopaque, info: phantom.display.Output.Info, fields: []std.meta.FieldEnum(phantom.display.Output.Info)) anyerror!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const origInfo = try impl_info(ctx);

    var changeSize = false;
    var changeScale = false;
    var changeFormat = false;

    for (fields) |field| {
        switch (field) {
            .size => changeSize = true,
            .scale => changeScale = true,
            .colorFormat => changeFormat = true,
            else => return error.UnsupportedField,
        }
    }

    if (changeScale) self.scale.value = info.scale.value;

    var i: u32 = 0;
    while (i < self.protocol.mode.max_mode) : (i += 1) {
        var modeInfo: *std.os.uefi.protocol.GraphicsOutput.Mode.Info = undefined;
        var info_size: usize = undefined;
        if (self.protocol.queryMode(i, &info_size, &modeInfo) != .Success) continue;

        if (self.infoFromMode(modeInfo) catch null) |infoMode| {
            const matchesSize = infoMode.size.res.eq(if (changeSize) info.size.res else origInfo.size.res);
            const matchesFormat = infoMode.colorFormat.eq(if (changeFormat) info.colorFormat else origInfo.colorFormat);

            if (matchesSize and matchesFormat) {
                try self.protocol.setMode(i).err();
                return;
            }
        }
    }

    return error.UnmatchedMode;
}

fn impl_deinit(ctx: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.surface) |surface| surface.base.deinit();
    self.display.allocator.destroy(self);
}
