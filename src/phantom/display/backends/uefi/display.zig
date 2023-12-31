const std = @import("std");
const Allocator = std.mem.Allocator;
const phantom = @import("phantom");
const Output = @import("output.zig");
const Self = @This();

allocator: Allocator,
kind: phantom.display.Base.Kind,
output: ?*Output,

pub fn init(alloc: Allocator, kind: phantom.display.Base.Kind) Self {
    return .{
        .allocator = alloc,
        .kind = kind,
        .output = null,
    };
}

pub fn deinit(self: *Self) void {
    if (self.output) |o| o.base.deinit();
}

pub fn display(self: *Self) phantom.display.Base {
    return .{
        .vtable = &.{
            .outputs = impl_outputs,
        },
        .type = @typeName(Self),
        .ptr = self,
        .kind = self.kind,
    };
}

fn impl_outputs(ctx: *anyopaque) anyerror!std.ArrayList(*phantom.display.Output) {
    const self: *Self = @ptrCast(@alignCast(ctx));
    var outputs = try std.ArrayList(*phantom.display.Output).initCapacity(self.allocator, 1);
    errdefer outputs.deinit();

    if (self.output) |output| {
        outputs.appendAssumeCapacity(@constCast(&output.base));
    } else {
        var protocol: ?*std.os.uefi.protocol.GraphicsOutput = undefined;
        try std.os.uefi.system_table.boot_services.?.locateProtocol(&std.os.uefi.protocol.GraphicsOutput.guid, null, @as(*?*anyopaque, @ptrCast(&protocol))).err();

        if (protocol) |proto| {
            self.output = try Output.new(self, proto);
            outputs.appendAssumeCapacity(@constCast(&self.output.?.base));
        } else return error.BadProtocol;
    }

    return outputs;
}
