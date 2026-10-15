const std = @import("std");
const cli = @import("cli");

const Abode = @import("Abode");
const cli_main = @import("cli/main.zig");

var config = struct {
    host: []const u8 = "localhost",
    port: u16 = 8080,
}{};

var command_init: std.process.Init = undefined;

pub fn main(init: std.process.Init) !void {
    command_init = init;

    var r = cli.AppRunner.init(&init);
    defer r.deinit();

    const app = cli.App{ .command = cli.Command{
        .name = "Abode",
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
                    .exec = runInit,
                },
            },
        }, .{
            .name = "verify",
            .description = .{
                .one_line = "Verify the folders and config file created by init",
            },
            .target = .{
                .action = .{
                    .exec = runVerify,
                },
            },
        } }) },
    }, .version = "0.1.0", .author = "ADormantSakthi" };
    return r.run(&app);
}

fn runInit() !void {
    try cli_main.init_cmd(command_init);
}

fn runVerify() !void {
    try cli_main.verify_cmd(command_init);
}
