const std = @import("std");
const builtin = @import("builtin");

const Dir = std.Io.Dir;

const key = switch (builtin.os.tag) {
    .windows => "USERPROFILE",
    .linux, .macos => "HOME",
    else => null
};

/// Function returns the String path to home directory for the current OS
/// @returns []const u8
/// @throws {UnsupportedPlatform} if not Windows, Linux, or MacOS
/// @throws {InvalidHomeDirectory} home directory is invalid
pub fn get_home_dir(init: std.process.Init) ![]const u8 {
    const home = init.environ_map.get(key) orelse return error.InvalidHomeDirectory;

    if (home.len == 0 or !std.fs.path.isAbsolute(home)) {
        return error.InvalidHomeDirectory;
    }

    return home;
}

/// Function returns the Dir for local workspace
/// @returns Dir
/// @throws {InvalidHomeDirectory} home directory is invalid
/// @throws {OpenError} if opening dir API failed
pub fn get_local_workspace_dir(init: std.process.Init) !Dir {
    const io = init.io;

    const home = init.environ_map.get(key) orelse return error.InvalidHomeDirectory;

    if (home.len == 0 or !std.fs.path.isAbsolute(home)) {
        return error.InvalidHomeDirectory;
    }

    const home_dir = try Dir.openDirAbsolute(io, home, .{});

    return try home_dir.openDir(io, ".local/share/abode");
}

/// Function to expand path string by replacing ~ by the OS home directory
/// @returns []const u8
/// @throws {ExpectedHomeRelativePath} there is no ~ at the start of the path string
pub fn expand_home_path(init: std.process.Init, path: []const u8) ![]u8 {
    const home = get_home_dir(init);

    if (!std.mem.startsWith(u8, path, "~/")) {
        return error.ExpectedHomeRelativePath;
    }
    
    if (std.mem.eql(u8, path, "~")) {
        return init.gpa.dupe(u8, home);
    }

    return std.fs.path.join(init.gpa, &.{ home, path[2..] });
}
