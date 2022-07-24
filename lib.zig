const std = @import("std");

// add default value based on type field
pub fn FlagOf(comptime T: type) type {
    return struct {
        const Self = @This();

        name: []const u8,
        parseFunc: fn([]const u8) anyerror!T,
        default: ?T = null,
        alias: ?[]const u8 = null,
        desc: ?[]const u8 = null,

        // TODO: parse all at once
        pub fn getValue(comptime self: Self) !T {
            // Get osArg value
            var os_val = "abc";
            std.log.info("os value is interpreted to be: {s}", .{os_val});
            return self.parseFunc(os_val);
        }
    };
}

// for printing
const Flag = struct {
    type:     type,
    name:     []const u8 = null,
    alias:   ?[]const u8 = null,
    default: ?[]const u8 = null,
    desc:    ?[]const u8 = null,
};

fn osArgsKV() void {

}


// TODO: create globals to store comptime stuff
// TODO: allow custom parsing function
// TODO: parse default value at comptime
// parseFunc: fn([]const u8) type,


// 
fn RegisterAll() void {

}


    // TODO: add debug function to property print those elems
