const std = @import("std");
const assert = std.debug.assert;

/// This function inits the project on the user's device
pub fn init() !void {
    std.debug.print("Init Command Triggered", .{});
}
