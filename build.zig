const std = @import("std");
const Phantom = @import("phantom");

pub const phantomModule = Phantom.Sdk.PhantomModule{
    .provides = .{
        .displays = &.{"uefi"},
    },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_importer = b.option(bool, "no-importer", "disables the import system (not recommended)") orelse false;
    const no_docs = b.option(bool, "no-docs", "skip installing documentation") orelse false;
    const no_tests = b.option(bool, "no-tests", "skip generating tests") orelse false;
    const scene_backend = b.option(Phantom.SceneBackendType, "scene-backend", "The scene backend to use for the example") orelse .headless;

    const metaplus = b.dependency("meta+", .{
        .target = target,
        .optimize = optimize,
    });

    const vizops = b.dependency("vizops", .{
        .target = target,
        .optimize = optimize,
    });

    const phantom = b.dependency("phantom", .{
        .target = target,
        .optimize = optimize,
        .@"no-importer" = no_importer,
    });

    const module = b.addModule("phantom.display.uefi", .{
        .root_source_file = .{ .path = b.pathFromRoot("src/phantom.zig") },
        .imports = &.{
            .{
                .name = "meta+",
                .module = metaplus.module("meta+"),
            },
            .{
                .name = "vizops",
                .module = vizops.module("vizops"),
            },
            .{
                .name = "phantom",
                .module = phantom.module("phantom"),
            },
        },
    });

    const exe_options = b.addOptions();
    exe_options.addOption(Phantom.SceneBackendType, "scene_backend", scene_backend);

    const exe_example = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{
            .path = b.pathFromRoot("src/example.zig"),
        },
        .target = target,
        .optimize = optimize,
    });
    exe_example.root_module.addImport("phantom", phantom.module("phantom"));
    exe_example.root_module.addImport("phantom.display.uefi", module);
    exe_example.root_module.addImport("options", exe_options.createModule());
    exe_example.root_module.addImport("vizops", vizops.module("vizops"));
    b.installArtifact(exe_example);

    if (!no_tests) {
        const step_test = b.step("test", "Run all unit tests");

        const unit_tests = b.addTest(.{
            .root_source_file = .{
                .path = b.pathFromRoot("src/phantom.zig"),
            },
            .target = target,
            .optimize = optimize,
        });

        unit_tests.root_module.addImport("meta+", metaplus.module("meta+"));
        unit_tests.root_module.addImport("vizops", vizops.module("vizops"));
        unit_tests.root_module.addImport("phantom", phantom.module("phantom"));

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
}
