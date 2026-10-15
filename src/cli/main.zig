const std = @import("std");
const init_commands = @import("init_command_funcs.zig");
const verify_commands = @import("verify_command_funcs.zig");

/// This function inits the project on the user's device
pub fn init_cmd(init: std.process.Init) !void {
    std.debug.print("Init Command Triggered\n", .{});

    try init_commands.create_config_files(init);
    try init_commands.create_local_store_files(init);
}

/// This function will check integrity of the folders
pub fn verify_cmd(init: std.process.Init) !void {
    try verify_commands.verify_setup(init);
}
