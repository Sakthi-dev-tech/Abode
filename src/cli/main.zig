const std = @import("std");
const init_commands = @import("init_command_funcs.zig");
const verify_commands = @import("verify_command_funcs.zig");
const add_file_commands = @import("add_file_tracking_funcs.zig");

/// This function inits the project on the user's device
pub fn init_cmd(init: std.process.Init) !void {
    std.debug.print("Init Command Triggered\n", .{});

    try init_commands.create_config_files(init);
    try init_commands.create_local_store_files(init);
}

/// This function will check integrity of the folders
pub fn verify_cmd(init: std.process.Init) bool {
    return verify_commands.verify_setup(init);
}

/// This function will add the provided file to be tracked
pub fn add_file_cmd(init: std.process.Init, sub_path: []const u8) !void {
    try add_file_commands.add_file_to_track(init, sub_path);
}
