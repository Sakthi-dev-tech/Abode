const std = @import("std");
const builtin = @import("builtin");
const home_dir_funcs = @import("../utils/home_dir_resolve.zig");

const dir = std.Io.Dir;

/// Create all required config files for Abode
pub fn create_config_files(init: std.process.Init) !void {
    const io = init.io;

    const allocator = init.arena.allocator();

    // Get the absolute path to the location of the config folder
    const home_dir = try home_dir_funcs.get_home_dir(init);
    const absolute_path = try std.fs.path.join(
        allocator,
        &.{ home_dir, ".config", "abode" },
    );
    defer allocator.free(absolute_path);

    // Create the config folder
    dir.createDirAbsolute(io, absolute_path, .default_dir) catch |err| {
        try catch_error_while_creating(err, "Config folder already exists!\n");
    };

    // Get the config_dir Dir struct
    const config_dir = try dir.openDirAbsolute(io, absolute_path, .{});
    defer config_dir.close(io);

    // Create the config.toml file
    const config_file = try config_dir.createFile(io, "config.toml", .{ .read = true, .truncate = false });
    defer config_file.close(io);
}

/// Create required folders for storing local copy of sync files
/// This will become a git repository connected to the user's remote repository
pub fn create_local_store_files(init: std.process.Init) !void {
    const io = init.io;

    const allocator = init.gpa;

    // Get absolute path to the location of the local copy of my files to init the workspace
    const workspace_dir = try home_dir_funcs.get_home_dir(init);
    const absolute_path = try std.fs.path.join(allocator, &.{ workspace_dir, ".local", "share", "abode" });
    defer allocator.free(absolute_path);

    // Create the local workspace folder
    dir.createDirAbsolute(io, absolute_path, .default_dir) catch |err| {
        try catch_error_while_creating(err, "Local workspace folder already exits\n");
    };

    const local_workspace_dir = try dir.openDirAbsolute(io, absolute_path, .{});
    defer local_workspace_dir.close(io);

    local_workspace_dir.createDir(io, "roots", .default_dir) catch |err| {
        try catch_error_while_creating(err, "Roots folder in local workspace folder already exists!\n");
    };
}

/// Handle error during file/folder creation
fn catch_error_while_creating(err: anyerror, path_exists_debug_print: []const u8) !void {
    switch (err) {
        error.PathAlreadyExists => {
            std.debug.print("{s}", .{path_exists_debug_print});
        },
        error.PermissionDenied => {
            std.debug.print("Permission denied!", .{});
            return err;
        },
        else => {
            std.debug.print("Unknown error occured. Error: {}\n", .{err});
            return err;
        },
    }
}
