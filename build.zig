const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const embed_gen = b.addExecutable(.{
        .name = "embed_gen",
        .root_source_file = .{ .path = "game/output_embeds.zig" },
    });
    const gen_step = b.addRunArtifact(embed_gen);

    const game = b.addSharedLibrary(.{
        .name = "game",
        .root_source_file = .{ .path = "game/wasm.zig" },
        .target = .{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        },
        .optimize = .ReleaseSmall,
    });
    game.rdynamic = true;
    game.step.dependOn(&gen_step.step);
    b.installArtifact(game);

    const bindgen = b.addExecutable(.{
        .name = "bindgen",
        .root_source_file = .{ .path = "game/output_definitions.zig" },
    });
    const run_bindgen = b.addRunArtifact(bindgen);
    b.getInstallStep().dependOn(&run_bindgen.step);

    const copy_output_to_root = b.addInstallBinFile(game.getEmittedBin(), "../../web/wasm/game.wasm");
    b.getInstallStep().dependOn(&copy_output_to_root.step);


    {
        const http_server_build = b.dependency("http_server", .{});
        const file_server = http_server_build.artifact("fileserver");
        const run_file_server = b.addRunArtifact(file_server);
        run_file_server.cwd = b.pathFromRoot("web");
        b.step("serve", "Serve the game files").dependOn(&run_file_server.step);
    }
}
