const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "rbd",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    var wasm_exe = b.addExecutable(.{
        .name = "rbd_wasm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wasm.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
        }),
    });

    wasm_exe.global_base = 6560;
    wasm_exe.entry = .disabled;
    wasm_exe.rdynamic = true;
    wasm_exe.import_memory = true;
    wasm_exe.stack_size = std.wasm.page_size;

    // wasm_exe.initial_memory = std.wasm.page_size * number_of_pages;
    // wasm_exe.max_memory = std.wasm.page_size * number_of_pages;

    b.installArtifact(wasm_exe);

    const wasm_cmd = b.addInstallArtifact(wasm_exe, .{ .dest_dir = .{ .override = .{ .custom = "../frontend/wasm/" } } });
    wasm_cmd.step.dependOn(b.getInstallStep());

    const wasm_step = b.step("wasm", "Build for wasm");
    wasm_step.dependOn(&wasm_cmd.step);
}
