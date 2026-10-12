const std = @import("std");
const cli = @import("cli");

const FoldRelay = @import("FoldRelay");
const cli_main = @import("cli/main.zig");

const Io = std.Io;

var config = struct {
    host: []const u8 = "localhost",
    port: u16 = undefined,
}{};

pub fn main(init: std.process.Init) !void {
    var r = cli.AppRunner.init(&init);
    defer r.deinit();

    const app = cli.App{ 
        .command = cli.Command{
        .name = "FoldRelay",
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
                .required = true,
                .value_ref = r.mkRef(&config.port),
            },
        }),
        .target = cli.CommandTarget{ 
            .subcommands = try r.allocCommands(&.{.{ 
                .name = "init",
                .description = .{
                    .one_line = "Initialise FoldRelay",
                },
                .target = .{
                    .action = .{
                        .exec = cli_main.init
                    },
                },
            }})
        },
    }, .version = "0.1.0", .author = "ADormantSakthi" };
    return r.run(&app);
}

fn runAction() !void {
    try cli_main.run(&config);
}
