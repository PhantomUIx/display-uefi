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

const alloc = if (builtin.link_libc) std.heap.c_allocator else if (builtin.os.tag == .uefi) std.os.uefi.pool_allocator else std.heap.page_allocator;

const displayBackend = phantom.display.Backend(.uefi);

const sceneBackendType: phantom.scene.BackendType = @enumFromInt(@intFromEnum(options.scene_backend));
const sceneBackend = phantom.scene.Backend(sceneBackendType);

fn simpleTextOutputWrite(sto: *std.os.uefi.protocol.SimpleTextOutput, buf: []const u8) !usize {
    const buf16 = try std.unicode.utf8ToUtf16LeWithNull(alloc, buf);
    defer alloc.free(buf16);
    try sto.outputString(buf16).err();
    return buf.len;
}

const SimpleTextOutputWriter = std.io.Writer(*std.os.uefi.protocol.SimpleTextOutput, std.os.uefi.Status.EfiError || std.mem.Allocator.Error || error{InvalidUtf8}, simpleTextOutputWrite);

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, ret: ?usize) noreturn {
    const stderr = SimpleTextOutputWriter{
        .context = std.os.uefi.system_table.std_err.?,
    };

    _ = stderr.print("{s} {any}\n", .{ msg, ret orelse @returnAddress() }) catch {};
    std.os.exit(1);
}

pub fn main() void {
    const stderr = SimpleTextOutputWriter{
        .context = std.os.uefi.system_table.std_err.?,
    };

    var display = displayBackend.Display.init(alloc, .compositor);
    defer display.deinit();

    _ = stderr.print("{}\n", .{display}) catch {};

    const outputs = @constCast(&display.display()).outputs() catch |e| @panic(@errorName(e));
    defer outputs.deinit();

    if (outputs.items.len == 0) {
        @panic("No outputs");
    }

    const output = outputs.items[0];
    _ = stderr.print("{}\n", .{output}) catch {};

    const surface = output.createSurface(.output, .{
        .size = (output.info() catch |e| @panic(@errorName(e))).size.res,
    }) catch |e| @panic(@errorName(e));
    defer {
        surface.destroy() catch {};
        surface.deinit();
    }
    _ = stderr.print("{}\n", .{surface}) catch {};

    const scene = surface.createScene(@enumFromInt(@intFromEnum(sceneBackendType))) catch |e| @panic(@errorName(e));
    _ = stderr.print("{}\n", .{scene}) catch {};

    const flex = scene.createNode(.NodeFlex, .{
        .direction = phantom.painting.Axis.horizontal,
        .children = &[_]*phantom.scene.Node{
            scene.createNode(.NodeArc, .{
                .radius = @as(f32, 32.0),
                .angles = vizops.vector.Float32Vector2.init([_]f32{ 0, std.math.tau - 0.0001 }),
                .color = vizops.color.Any{
                    .uint8 = .{
                        .sRGB = .{
                            .value = .{ 255, 0, 0, 255 },
                        },
                    },
                },
            }) catch |e| @panic(@errorName(e)),
            scene.createNode(.NodeRect, .{
                .color = vizops.color.Any{
                    .uint8 = .{
                        .sRGB = .{
                            .value = .{ 0, 255, 0, 255 },
                        },
                    },
                },
                .size = vizops.vector.Float32Vector2.init([_]f32{ 10.0, 10.0 }),
            }) catch |e| @panic(@errorName(e)),
        },
    }) catch |e| @panic(@errorName(e));
    defer flex.deinit();

    _ = stderr.print("{}\n", .{flex}) catch {};

    _ = scene.frame(flex) catch |e| @panic(@errorName(e));
    while (true) {}
}
