const std = @import("std");
const cli = @import("cli");
const constants = @import("constants.zig");

const assert = std.debug.assert;

const Abode = @import("Abode");
const AddFunctions = @import("commands/add.zig").AddFunctions;
const InitFunctions = @import("commands/init.zig").InitFunctions;
const VerifyFunctions = @import("commands/verify.zig").VerifyFunctions;

var config = struct {
    host: []const u8 = "localhost",
    port: u16 = 8080,
}{};

var command_init: std.process.Init = undefined;

// Add command variables
var file_subpath: []const u8 = undefined;

// Flag to ensure undefined vars are Initialised
var initialised_undefined: bool = false;

pub fn main(init: std.process.Init) !void {
    command_init = init;

    var r = cli.AppRunner.init(&init);
    defer r.deinit();

    const app = cli.App{ .command = cli.Command{
        .name = "abode",
        .description = cli.Description{ .one_line = "Your files will be the same on all your devices" },
        .options = try r.allocOptions(&.{
            .{
                .long_name = "host",
                .help = "Host to listen on",
                .value_ref = r.mkRef(&config.host),
            },
            .{
                .long_name = "port",
                .help = "Port to bind to",
                .required = false,
                .value_ref = r.mkRef(&config.port),
            },
        }),
        .target = cli.CommandTarget{ .subcommands = try r.allocCommands(&.{ .{
            .name = "init",
            .description = .{
                .one_line = "Initialise Abode",
            },
            .target = .{
                .action = .{
                    .exec = run_init,
                },
            },
        }, .{
            .name = "verify",
            .description = .{
                .one_line = "Verify the folders and config file created by init",
            },
            .target = .{
                .action = .{
                    .exec = run_verify,
                },
            },
        }, .{
            .name = "add",
            .description = .{
                .one_line = "Add a file to set up tracking given the relative path name" 
            },
            .target = .{
                .action = .{ 
                    .exec = run_add_file,
                }, 
            },
            .options = try r.allocOptions(&.{
                .{
                    .long_name = "path",
                    .short_alias = 'p',
                    .help = "Use this command in order to add a file in your current working directory to track",
                    .required = true,
                    .value_ref = r.mkRef(&file_subpath)
                }
            })
        } }) },
    }, .version = "0.1.0", .author = "ADormantSakthi" };

    initialised_undefined = true;
    return r.run(&app);
}

fn run_init() !void {
    assert(initialised_undefined != false);
    const init_instance = InitFunctions {
        .init = command_init
    };

    try init_instance.create_config_files();
    try init_instance.create_local_store_files();
}

fn run_verify() !void {
    assert(initialised_undefined != false);
    const verify_instance = VerifyFunctions {
        .init = command_init
    };

    const verified = verify_instance.verify_setup();
    if (verified) std.debug.print("{s}Abode setup verified successfully.{s}\n", .{ constants.green_code,  constants.reset_code });
}

fn run_add_file() !void {
    assert(initialised_undefined != false);
    const add_instance = AddFunctions {
        .init = command_init
    };

    try add_instance.add_file_to_track(file_subpath);
}
