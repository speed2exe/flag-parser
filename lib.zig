const std = @import("std");
const info = std.log.info;

// add default value based on type field
pub fn FlagOf(comptime T: type) type {
    return struct {
        const Self = @This();

        name:       []const u8,
        parse_func: fn([]const u8) anyerror!T,
        default:    ?T                       = null,
        alias:      ?[]const u8              = null,
        desc:       ?[]const u8              = null,
    };
}

pub fn getOsArgKeyValue() !std.StringHashMap([]const u8) {
    var osKeyValue = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    var os_args_consumer = OsArgsConsumer{};
    while (os_args_consumer.consume()) |result| {
        _ = result;
    }

    return osKeyValue;
}

const KeyValue = struct {
    key: []const u8,
    value: ?[]const u8,
};

const OsArgsConsumer = struct {
    os_args: [][*:0]const u8,

    fn popFromStart(self: *OsArgsConsumer) [*:0]const u8 {
        defer self.os_args = self.os_args[1..];
        return self.os_args[0];
    }

    fn consume(self: *OsArgsConsumer) ?KeyValue {
        if (self.os_args.len == 0) {
            return null;
        }
        
        

        const next = self.popFromStart();
        _ = next;
        
        return null;
    }
};

// example: --number=8
fn equal(str: [*:0]const u8) ?KeyValue {
    _ = str;
    return null;
}

pub fn consumeOsArgs(args: [][*:0]const u8) void {
    _ = args;
}

pub fn main() !void {
    info("return: {}", .{returnOptErr()});
    
    while (returnOptErr()) |value| {
        info("in while loop value: {}", .{value});
    }

}

fn returnOptErr() ?i8 {
    return 8;
}

