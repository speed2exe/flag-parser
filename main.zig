const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() void {
    // comptime known
    const I8FlagType = lib.FlagOf(i8);
    const num_flag: I8FlagType = .{.name = "num", .parseFunc = parsei8};

    std.log.info("{s}", .{@TypeOf(num_flag)});
    std.log.info("{s}", .{num_flag});

    const val: anyerror!i8 = num_flag.getValue();

    std.log.info("val type is {}", .{@TypeOf(val)});
    std.log.info("{}", .{val});
}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}

fn sayHi() void {}
