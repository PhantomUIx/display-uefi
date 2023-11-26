const std = @import("std");
const vizops = @import("vizops");

pub fn import(comptime phantom: type) type {
    const Display = @import("display.zig").import(phantom);
    const Surface = @import("surface.zig").import(phantom);

    return struct {
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

        fn infoFromMode(self: *Self, info: *std.os.uefi.protocol.GraphicsOutput) !phantom.display.Output.Info {
            const res = vizops.vector.UsizeVector2.init(.{
                @as(usize, @intCast(info.horizontal_resolution)),
                @as(usize, @intCast(info.vertical_resolution)),
            });

            return .{
                .enabled = true,
                .size = .{
                    .phys = res.cast(f32),
                    .res = res,
                },
                .scale = self.scale,
                .name = "UEFI GOP",
                .manufacturer = std.os.uefi.system_table.firmware_vendor[0..std.os.uefi.system_table.firmware_vendor.len],
                .format = try switch (info.pixel_format) {
                    .RedGreenBlueReserved8BitPerColor => .{
                        .rgbx = .{
                            info.red_mask * @sizeOf(u8),
                            info.green_mask * @sizeOf(u8),
                            info.blue_mask * @sizeOf(u8),
                        },
                    },
                    .BlueGreenRedReserved8BitPerColor => .{
                        .bgrx = .{
                            info.blue_mask * @sizeOf(u8),
                            info.green_mask * @sizeOf(u8),
                            info.red_mask * @sizeOf(u8),
                        },
                    },
                    else => error.InvalidPixelFormat,
                },
            };
        }

        fn impl_create_surface(ctx: *anyopaque, kind: phantom.display.Surface.Kind, _: phantom.display.Surface.Info) anyerror!*phantom.display.Surface {
            const self: *Self = @ptrCast(@alignCast(ctx));

            if (kind != .output) return error.InvalidKind;
            if (self.surface) |_| return error.AlreadyExists;

            self.surface = try Surface.new(self);
            return self.surface.?;
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
                    .format => changeFormat = true,
                    else => return error.UnsupportedField,
                }
            }

            if (changeScale) self.scale = info.scale;

            var i: usize = 0;
            while (i < self.protocol.mode.max_mode) : (i += 1) {
                var modeInfo: *std.os.uefi.protocol.GraphicsOutput.Mode.Info = undefined;
                var info_size: usize = undefined;
                if (self.protocol.queryMode(i, &info_size, &modeInfo) != .Success) continue;

                if (self.infoFromMode(modeInfo)) |infoMode| {
                    const matchesSize = infoMode.size.res.eq(if (changeSize) info.size.res else origInfo.size.res);
                    const matchesFormat = infoMode.format.eq(if (changeFormat) info.format else origInfo.format);

                    if (matchesSize and matchesFormat) {
                        try self.protocol.setMode(i).status();
                        return;
                    }
                } else continue;
            }

            return error.UnmatchedMode;
        }

        fn impl_deinit(ctx: *anyopaque) void {
            const self: *Self = @ptrCast(@alignCast(ctx));
            if (self.surface) |surface| surface.deinit();
            self.display.allocator.destroy(self);
        }
    };
}
