const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() void {
    
    // 1st way:
    const flags1: []const lib.Flag = &.{
        .{
            .type = i8,
            .name = "number",
        },
    };
    std.log.info("{s}", .{@TypeOf(flags1)});
    lib.setup(flags1);

    // 2st way:
    const flags2 = [_]lib.Flag {
        lib.Flag {
            .type = []const u8,
            .name = "number",
        },
    };
    std.log.info("{s}", .{@TypeOf(flags2)});
    lib.setup(flags1);


    std.log.info("{s}", .{@TypeOf(sayHi)});
}

fn sayHi() void {}
