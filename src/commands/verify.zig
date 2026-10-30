const std = @import("std");
const constants = @import("../constants.zig");
const get_paths_funcs = @import("../utils/get_paths.zig");

pub const VerifyFunctions = struct {
    init: std.process.Init,

    /// Verify the structure created by init without changing files or checking sync contents.
    /// Will print statements when there are warnings only
    pub fn verify_setup(self: *const VerifyFunctions, allocator: std.mem.Allocator) bool {
        const init = self.init;

        const home_dir = get_paths_funcs.get_home_dir_path(init) catch |err| {
            std.debug.print("{s}Cannot resolve home directory: {s}{s}\n", .{ constants.yellow_code, @errorName(err), constants.reset_code });
            return false;
        };
        const required_paths = [_]struct { []const u8, std.Io.File.Kind }{
            .{ ".config/abode", std.Io.File.Kind.directory },
            .{ ".config/abode/config.toml", std.Io.File.Kind.file },
            .{ ".local/share/abode", std.Io.File.Kind.directory },
        };

        var valid = true;
        for (required_paths) |required| {
            const path = std.fs.path.join(allocator, &.{ home_dir, required[0] }) catch |err| {
                std.debug.print("{s}Cannot construct setup path for {s}: {s}{s}\n", .{ constants.yellow_code, required[0], @errorName(err), constants.reset_code });
                return false;
            };
            defer allocator.free(path); // We would not need this path once checked so we can free it immediately aft

            const stat = std.Io.Dir.cwd().statFile(init.io, path, .{}) catch |err| {
                std.debug.print("{s}Cannot verify {s}: {s}{s}\n", .{ constants.yellow_code, path, @errorName(err), constants.reset_code });
                valid = false;
                continue;
            };

            if (stat.kind != required[1]) {
                std.debug.print("{s}Invalid setup at {s}: expected {s}, found {s}{s}\n", .{
                    constants.yellow_code, path, @tagName(required[1]), @tagName(stat.kind), constants.reset_code,
                });
                valid = false;
            }
        }

        if (!valid) {
            std.debug.print("{s}Abode setup is incomplete. Run 'abode init' to create missing folders and config.toml.{s}\n", .{ constants.yellow_code, constants.reset_code });
            return false;
        }

        return valid;
    }
};
