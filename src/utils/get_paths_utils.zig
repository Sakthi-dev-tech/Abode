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

    return std.mem.trimEnd(u8, home, if (builtin.os.tag == .windows) "/\\" else "/");
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
/// @throws {InvalidHomeDirectory} home directory is invalid
pub fn expand_home_path(init: std.process.Init, path: []const u8) ![]u8 {
    const home = try get_home_dir(init);

    if (!std.mem.startsWith(u8, path, "~/")) {
        return error.ExpectedHomeRelativePath;
    }
    
    if (std.mem.eql(u8, path, "~")) {
        return init.gpa.dupe(u8, home);
    }

    return std.fs.path.join(init.arena.allocator(), &.{ home, path[2..] });
}

/// Replace the home directory prefix with ~, leaving paths outside home unchanged.
/// @returns []const u8
pub fn get_universal_path(init: std.process.Init, expanded_file_path: []const u8) ![]const u8 {
    const home_dir_path = try get_home_dir(init);

    if (!std.mem.startsWith(u8, expanded_file_path, home_dir_path)) {
        return error.UnsupportedPath; // this path is not within the home directory of the OS
    }

    const suffix = expanded_file_path[home_dir_path.len + 1..];
    if (suffix.len > 0 and std.fs.path.isSep(suffix[0])) {
        return expanded_file_path;
    }

    return try std.mem.concat(init.arena.allocator(), u8, &.{ suffix });
}
