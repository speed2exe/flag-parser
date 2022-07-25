const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() void {
    // comptime known
    const I8FlagType = lib.FlagOf(i8);
    const num_flag: I8FlagType = .{.name = "number", .parseFunc = parsei8};

    std.log.info("{s}", .{@TypeOf(num_flag)});
    std.log.info("{s}", .{num_flag});

    var inited = num_flag.init();
    std.log.info("{s}", .{@TypeOf(inited)});
    std.log.info("{s}", .{inited});

}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}
