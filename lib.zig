const std = @import("std");

// add default value based on type field
pub const Flag = struct {
    type: type, // replace with generic struct
    name: []const u8,
    alias: ?[]const u8 = null,
    desc: ?[]const u8 = null,
};

pub fn setup (comptime flags: []const Flag) void {
    std.log.info("flags: {*}", .{flags});
    // const args = std.os.argv;
    // std.log.info("args: {s}", .{args});
}

// TODO: Improve on this
pub fn flagOf(comptime T: type) type {
    return struct {
        _type: type = T,
        name: []const u8,
        default: T,
        alias: ?[]const u8 = null,
        desc: ?[]const u8 = null,
        default: ?[]const u8 = null,
    };
}

// use case: lib.flagOf(u8){.default = ...(u8 value), .name = ..., .alias = ...}
