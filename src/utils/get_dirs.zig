const std = @import("std");
const builtin = @import("builtin");

const Dir = std.Io.Dir;

const key = switch (builtin.os.tag) {
    .windows => "USERPROFILE",
    .linux, .macos => "HOME",
    else => null,
};

/// Function returns the Dir for local Abode folder
///
/// @returns Dir
///
/// @throws {InvalidHomeDirectory} home directory is invalid
/// @throws {OpenError} if opening dir API failed
pub fn get_local_workspace_dir(init: std.process.Init) !Dir {
    const io = init.io;

    const home = init.environ_map.get(key) orelse return error.InvalidHomeDirectory;

    if (home.len == 0 or !std.fs.path.isAbsolute(home)) {
        return error.InvalidHomeDirectory;
    }

    const home_dir = try Dir.openDirAbsolute(io, home, .{});

    return try home_dir.openDir(
        io,
        ".local/share/abode",
        .{
            .access_sub_paths = true,
            .iterate = true
        }
    );
}

