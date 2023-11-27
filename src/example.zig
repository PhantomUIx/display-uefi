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
    const colors: []const [17]vizops.color.Any = &.{
        .{
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xf7, 0x76, 0x8e, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xff, 0x9e, 0x64, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xe0, 0xaf, 0x68, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x9e, 0xce, 0x6a, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x73, 0xda, 0xca, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xb4, 0xf9, 0xf8, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x2a, 0xc3, 0xde, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x7d, 0xcf, 0xff, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x7a, 0xa2, 0xf7, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xbb, 0x9a, 0xf7, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xc0, 0xca, 0xf5, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xa9, 0xb1, 0xd6, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x9a, 0xa5, 0xce, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xcf, 0xc9, 0xc2, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x56, 0x5f, 0x89, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x41, 0x48, 0x68, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x1a, 0x1b, 0x26, 0xff },
                    },
                },
            },
        },
        .{
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xf7, 0x76, 0x8e, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xff, 0x9e, 0x64, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xe0, 0xaf, 0x68, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x9e, 0xce, 0x6a, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x73, 0xda, 0xca, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xb4, 0xf9, 0xf8, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x2a, 0xc3, 0xde, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x7d, 0xcf, 0xff, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x7a, 0xa2, 0xf7, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xbb, 0x9a, 0xf7, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xc0, 0xca, 0xf5, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xa9, 0xb1, 0xd6, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x9a, 0xa5, 0xce, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0xcf, 0xc9, 0xc2, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x56, 0x5f, 0x89, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x41, 0x48, 0x68, 0xff },
                    },
                },
            },
            .{
                .uint8 = .{
                    .sRGB = .{
                        .value = .{ 0x24, 0x28, 0x3b, 0xff },
                    },
                },
            },
        },
    };

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

    var children: [17]*phantom.scene.Node = undefined;

    for (&children, colors[0]) |*child, color| {
        child.* = scene.createNode(.NodeRect, .{
            .color = color,
            .size = vizops.vector.Float32Vector2.init([_]f32{ 100.0 / 17.0, 100.0 }),
        }) catch |e| @panic(@errorName(e));
    }

    const flex = scene.createNode(.NodeFlex, .{
        .direction = phantom.painting.Axis.horizontal,
        .children = &children,
    }) catch |e| @panic(@errorName(e));
    defer flex.deinit();

    _ = stderr.print("{}\n", .{flex}) catch {};

    while (true) {
        const seq = scene.seq;

        _ = scene.frame(flex) catch |e| @panic(@errorName(e));
        if (scene.seq != seq) _ = stderr.print("Frame #{}\n", .{scene.seq}) catch {};

        const palette = seq % colors.len;
        for (children, colors[palette]) |child, color| {
            child.setProperties(.{ .color = color }) catch |e| @panic(@errorName(e));
        }

        flex.setProperties(.{ .children = &children }) catch |e| @panic(@errorName(e));
    }
}
