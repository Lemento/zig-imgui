const std = @import("std");
const assert = std.debug.assert;

// 
// Cross Platform Makefile
// Compatible with MSYS2/MINGW, Ubuntu 14.04.1 and Mac OS X
// 
// You will need SDL2 (http://www.libsdl.org):
// Linux:
//   apt-get install libsdl2-dev
// Mac OS X:
//   brew install sdl2
// MSYS2:
//   pacman -S mingw-w64-i686-SDL2
// 

pub fn link( exe: *std.Build.CompileStep, comptime IMGUI_DIR: []const u8 ) void
{
    const CXX_FLAGS = &.{ "-std=c++11", "-g", "-Wall", "-Wformat" };
    const sources = &.
    {
        IMGUI_DIR ++ "imgui.cpp",
        IMGUI_DIR ++ "imgui_demo.cpp",
        IMGUI_DIR ++ "imgui_draw.cpp",
        IMGUI_DIR ++ "imgui_tables.cpp",
        IMGUI_DIR ++ "imgui_widgets.cpp",

        IMGUI_DIR ++ "backends/imgui_impl_sdl2.cpp",
        IMGUI_DIR ++ "backends/imgui_impl_opengl3.cpp"
    };

    exe.linkLibCpp();

    exe.addIncludePath(.{.path = IMGUI_DIR });
    exe.addIncludePath(.{.path = IMGUI_DIR ++ "backends" });

    exe.addCSourceFiles(sources, CXX_FLAGS);

    // Build flags per platform
    const target = (std.zig.system.NativeTargetInfo.detect(exe.target) catch unreachable).target;
    switch(target.os.tag)
    {
        .linux =>
        {
            assert(target.cpu.arch.isX86());

            exe.linkSystemLibrary("GL");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("sdl2");
        },
        .macos =>
        {
            exe.linkFramework("OpenGL");
            exe.linkFramework("Cocoa");
            exe.linkFramework("IOKit");
            exe.linkFramework("CoreVideo");
            exe.linkSystemLibrary("sdl2");
            exe.linkSystemLibrary("lib");
            exe.addLibraryPath(.{.path = "/usr/local/lib"});
            exe.addLibraryPath(.{.path = "/opt/local/lib"});
            exe.addIncludePath(.{.path = "/usr/local/include"});
            exe.addIncludePath(.{.path = "/opt/local/include"});
        },
        .windows =>
        {
            assert(target.cpu.arch.isX86());
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("opengl32");
            exe.linkSystemLibrary("imm32");
            exe.linkSystemLibrary("sdl2");
        },
        else => unreachable,
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "example_sdl2_opengl3",
        .root_source_file = .{.path = "main.cpp" },
        .target = target,
        .optimize = optimize
    });

    link(exe, "../../");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}