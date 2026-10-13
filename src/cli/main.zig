const std = @import("std");
const builtin = @import("builtin");

/// This function inits the project on the user's device
pub fn init_cmd(init: std.process.Init) !void {
    std.debug.print("Init Command Triggered\n", .{});

    try create_all_required_files(init);
}

/// Create all required config files for FoldRelay
fn create_all_required_files(init: std.process.Init) !void {
    const io = init.io;
    const dir = std.Io.Dir;

    const allocator = init.gpa;

    // Get the absolute path to the location of the config folder
    const home_env = if (builtin.os.tag == .windows) "USERPROFILE" else "HOME";
    const home = init.environ_map.get(home_env) orelse return error.HomeDirectoryNotFound;
    const absolute_path = try std.fs.path.join(
        allocator,
        &.{ home, ".config", "foldrelay" },
    );
    defer allocator.free(absolute_path);

    // Create the config folder
    dir.createDirAbsolute(io, absolute_path, .default_dir) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {
                std.debug.print("Path already exists: {s}\n", .{absolute_path});
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
    };

    // Get the config_dir Dir struct
    const config_dir = try dir.openDirAbsolute(io, absolute_path, .{});
    defer config_dir.close(io);

    // Create the config.toml file
    const config_file = try config_dir.createFile(
        io,
        "config.toml",
        .{ .read = true, .truncate = false }
        );
    defer config_file.close(io);
}
