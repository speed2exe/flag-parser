const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() void {
    // comptime known
    comptime {
        const I8FlagType = Flag(i8);
        const num_flag = I8FlagType.init("number", parsei8);
        _ = num_flag;

        @compileLog("hello", {});
    }

    // const num_flag = I8FlagType.init("number", parsei8).withAlias("num");
    // std.log.info("{s}", .{@TypeOf(num_flag)});
    // std.log.info("{s}", .{num_flag});
}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}

pub fn Flag(comptime T: type) type {
    return struct {
        const Self = @This();

        name:       []const u8,
        parse_func: fn([]const u8) anyerror!T,
        default:    ?T                       = null,
        alias:      ?[]const u8              = null,
        desc:       ?[]const u8              = null,

        pub fn init(name: []const u8, parse_func: fn([]const u8) anyerror!T) *Self {
            return &Self {
                .name = name,
                .parse_func = parse_func,
            };
        }

        pub fn withAlias(self: *Self, alias: []const u8) *Self {
            self.alias = alias;
            return self;
        }
    };
}


