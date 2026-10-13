const std = @import("std");
const builtin = @import("builtin");

const assert = std.debug.assert;

/// This function inits the project on the user's device
pub fn init_cmd(init: std.process.Init) !void {
    std.debug.print("Init Command Triggered\n", .{});

    const io = init.io;
    const allocator = init.gpa;

    // Get the absolute path to the config folder
    const home_env = if (builtin.os.tag == .windows) "USERPROFILE" else "HOME";
    const home = init.environ_map.get(home_env) orelse return error.HomeDirectoryNotFound;
    const absolute_path = try std.fs.path.join(
        allocator,
        &.{ home, ".config", "foldrelay" },
    );
    defer allocator.free(absolute_path);

    std.Io.Dir.createDirAbsolute(io, absolute_path, .default_dir) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {
                std.debug.print("Path already exists: {s}\n", .{absolute_path});
                return;
            },
            error.PermissionDenied => {
                std.debug.print("Permission denied!", .{});
            },
            else => {
                std.debug.print("Unknown error occured. Error: {}\n", .{err});
                return;
            },
        }
    };
}
