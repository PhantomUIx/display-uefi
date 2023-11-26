const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_docs = b.option(bool, "no-docs", "skip installing documentation") orelse false;

    const metaplus = b.dependency("metaplus", .{
        .target = target,
        .optimize = optimize,
    });

    const vizops = b.dependency("vizops", .{
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("phantom.display.uefi", .{
        .source_file = .{ .path = b.pathFromRoot("src/phantom.zig") },
        .dependencies = &.{
            .{
                .name = "meta+",
                .module = metaplus.module("meta+"),
            },
            .{
                .name = "vizops",
                .module = vizops.module("vizops"),
            },
        },
    });

    const step_test = b.step("test", "Run all unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = .{
            .path = b.pathFromRoot("src/phantom.zig"),
        },
        .target = target,
        .optimize = optimize,
    });

    unit_tests.addModule("meta+", metaplus.module("meta+"));
    unit_tests.addModule("vizops", vizops.module("vizops"));

    const run_unit_tests = b.addRunArtifact(unit_tests);
    step_test.dependOn(&run_unit_tests.step);

    if (!no_docs) {
        const docs = b.addInstallDirectory(.{
            .source_dir = unit_tests.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        });

        b.getInstallStep().dependOn(&docs.step);
    }
}
