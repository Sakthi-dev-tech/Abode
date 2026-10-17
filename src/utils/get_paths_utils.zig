const std = @import("std");
const builtin = @import("builtin");

pub fn get_home_dir(init: std.process.Init) ![]const u8 {
    const key = switch (builtin.os.tag) {
        .windows => "USERPROFILE",
        .linux, .macos => "HOME",
        else => return error.UnsupportedPlatform,
    };

    const home = init.environ_map.get(key) orelse return error.HomeDirectoryNotFound;

    if (home.len == 0 or !std.fs.path.isAbsolute(home)) {
        return error.InvalidHomeDirectory;
    }

    return home;
}

pub fn expand_home_path(init: std.process.Init, path: []const u8) ![]u8 {
    const home = get_home_dir(init);

    if (std.mem.eql(u8, path, "~")) {
        return init.gpa.dupe(u8, home);
    }

    if (!std.mem.startsWith(u8, path, "~/")) {
        return error.ExpectedHomeRelativePath;
    }

    return std.fs.path.join(init.gpa, &.{home, path[2..]});
}
