const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

const Dir = std.Io.Dir;

const key = switch (builtin.os.tag) {
    .windows => "USERPROFILE",
    .linux, .macos => "HOME",
    else => null,
};

/// Standerdise path seperators on all OS
///
/// @throws {OutOfMemory} when the dupe function fails
fn parse_path_separators(allocator: std.mem.Allocator, provided_path: []const u8) ![]const u8 {
    const owned_path = try allocator.dupe(u8, provided_path);
    for (owned_path) |*byte| {
        if (std.fs.path.isSep(byte.*)) {
            byte.* = '/';
        }
    }

    return owned_path;
}

/// Function returns the String path to home directory for the current OS
///
/// @returns []const u8
///
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

    return try home_dir.openDir(io, ".local/share/abode");
}

/// Function to expand path string by replacing ~ by the OS home directory
///
/// @returns []const u8
///
/// @throws {ExpectedHomeRelativePath} there is no ~ at the start of the path string
/// @throws {InvalidHomeDirectory} home directory is invalid
pub fn expand_home_path(init: std.process.Init, path: []const u8) ![]u8 {
    const allocator = init.arena.allocator();

    const home_path = try get_home_dir(init);
    const parsed_home_path = try parse_path_separators(allocator, home_path);

    const parsed_path = parse_path_separators(allocator, path);
    defer allocator.free(parsed_path);

    if (!std.mem.startsWith(u8, parsed_path, "~/")) {
        return error.ExpectedHomeRelativePath;
    }

    if (std.mem.eql(u8, parsed_path, "~")) {
        return allocator.dupe(u8, parsed_home_path);
    }

    return std.fs.path.join(allocator, &.{ parsed_home_path, parsed_path[2..] });
}

/// Replace the home directory prefix with ~, leaving paths outside home unchanged.
///
/// @returns []const u8
pub fn get_universal_path(init: std.process.Init, expanded_file_path: []const u8) ![]const u8 {
    const home_dir_path = try get_home_dir(init);
    const allocator = init.arena.allocator();

    const parsed_home_dir_path = try parse_path_separators(allocator, home_dir_path);
    const parsed_expanded_path = try parse_path_separators(allocator, expanded_file_path);

    defer {
        allocator.free(parsed_expanded_path);
        allocator.free(parsed_home_dir_path);
    }

    if (!std.mem.startsWith(u8, parsed_expanded_path, parsed_home_dir_path)) {
        return error.UnsupportedPath; // this path is not within the home directory of the OS
    }

    if (parsed_expanded_path.len < parsed_home_dir_path.len) {
        return error.UnsupportedPath; // the expanded file path is shorter than the home path
    }

    if (!std.fs.path.isSep(parsed_expanded_path[parsed_home_dir_path.len])) {
        return error.UnsupportedPath; // there is no separator right after the home address
    }

    const suffix = parsed_expanded_path[parsed_home_dir_path.len + 1 ..];
    if (suffix.len > 0 and std.fs.path.isSep(suffix[0])) {
        return parsed_expanded_path;
    }

    return try std.mem.concat(allocator, u8, &.{suffix});
}

/// Convert universal path into Abode compatible path
///
/// @returns Universal path converted into an Abode
/// @example .config/nvim/init.lua => dot_config/nvim/init.lua
pub fn parse_universal_path_into_abode_path(allocator: std.mem.Allocator, universal_path: []const u8) ![]const u8 {
    assert(universal_path.len > 0);

    const parsed_path = try parse_path_separators(allocator, universal_path);
    var iterator = std.mem.splitScalar(u8, parsed_path, '/');

    // iterate over the path chunks
    while (iterator.next()) |chunk| {
        std.debug.print("{s}\n", .{chunk});
    }

    return parsed_path;
}

// ======================================================================================
// TESTS
// ======================================================================================

test "parse path separators" {
    const allocator = std.testing.allocator;

    const result = try parse_universal_path_into_abode_path(
        allocator,
        ".config/nvim/init.lua",
    );
    defer allocator.free(result);

    std.debug.print("\nParsed path: {s}\n", .{result});
}
