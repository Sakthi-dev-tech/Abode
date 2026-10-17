const std = @import("std");
const home_dir_funcs = @import("../utils/home_dir_resolve.zig");

/// Verify the structure created by init without changing files or checking sync contents.
pub fn verify_setup(init: std.process.Init) bool {
    const yellow = "\x1b[33m";
    const green = "\x1b[32m";
    const reset = "\x1b[0m";

    const home_dir = home_dir_funcs.get_home_dir(init) catch |err| {
        std.debug.print("{s}Cannot resolve home directory: {s}{s}\n", .{ yellow, @errorName(err), reset });
        return false;
    };
    const required_paths = [_]struct { []const u8, std.Io.File.Kind }{
        .{ ".config/abode", std.Io.File.Kind.directory },
        .{ ".config/abode/config.toml", std.Io.File.Kind.file },
        .{ ".local/share/abode", std.Io.File.Kind.directory },
        .{ ".local/share/abode/roots", std.Io.File.Kind.directory },
    };

    var valid = true;
    for (required_paths) |required| {
        const path = std.fs.path.join(init.gpa, &.{ home_dir, required[0] }) catch |err| {
            std.debug.print("{s}Cannot construct setup path for {s}: {s}{s}\n", .{ yellow, required[0], @errorName(err), reset });
            return false;
        };
        defer init.gpa.free(path);

        const stat = std.Io.Dir.cwd().statFile(init.io, path, .{}) catch |err| {
            std.debug.print("{s}Cannot verify {s}: {s}{s}\n", .{ yellow, path, @errorName(err), reset });
            valid = false;
            continue;
        };

        if (stat.kind != required[1]) {
            std.debug.print("{s}Invalid setup at {s}: expected {s}, found {s}{s}\n", .{
                yellow, path, @tagName(required[1]), @tagName(stat.kind), reset,
            });
            valid = false;
        }
    }

    if (!valid) {
        std.debug.print("{s}Abode setup is incomplete. Run 'abode init' to create missing folders and config.toml.{s}\n", .{ yellow, reset });
        return false;
    }

    std.debug.print("{s}Abode setup verified successfully.{s}\n", .{ green, reset });
    return valid;
}
