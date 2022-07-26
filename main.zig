const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() void {

    // comptime known
    const I8FlagType = lib.FlagOf(i8);
    var num_flag: I8FlagType = .{.name = "number", .parseFunc = parsei8};

    std.log.info("{s}", .{@TypeOf(num_flag)});
    std.log.info("{s}", .{num_flag});



    // 

    const i8value: i8 = num_flag.init().get();
}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}
