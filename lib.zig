const std = @import("std");
const mem = std.mem;
const expect = std.testing.expect;
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
    while (try os_args_consumer.consume()) |result| {
        osKeyValue.put(result.key, result.value);
    }
    return osKeyValue;
}

const KeyValue = struct {
    key: []const u8,
    value: ?[]const u8,
};

const OsArgsConsumer = struct {
    os_args: [][*:0]const u8 = std.os.argv,

    fn popFromStart(self: *OsArgsConsumer) ?[]const u8 {
        if (self.os_args.len == 0) {
            return null;
        }
        defer self.os_args = self.os_args[1..];
        return self.os_args[0];
    }

    fn consume(self: *OsArgsConsumer) !?KeyValue {
        const next = self.popFromStart() orelse return null;

        if (startWithDash(next)) {
            next = trimDash(next);
        } else {
            std.log.err("invalid argument name found: {}", next);
            return error.InvalidArgs; // TODO: Pass value with error when possible
        }

        if (isArgNameEqualValueFormat()) |result| {
            return result;
        }

        const next2 = popFromStart() orelse return KeyValue{.key = next, .value = null};
        
        _ = next2;

    }
};

// example: --number=8
fn isArgNameEqualValueFormat(str: []const u8) ?KeyValue {
    _ = str;
    return null;
}

fn trimDash(str: []const u8) []const u8 {
    for (str) |b, i| {
        if (b != '-') {
            return str[i..];
        }
    }
    return "";
}

test "trimDash" {
    try expect(mem.eql(u8, trimDash("--help"), @as([]const u8, "help")));
    try expect(mem.eql(u8, trimDash("--"), @as([]const u8, "")));
    try expect(mem.eql(u8, trimDash(""), @as([]const u8, "")));
    try expect(mem.eql(u8, trimDash("- "), @as([]const u8, " ")));
    try expect(mem.eql(u8, trimDash("help"), @as([]const u8, "help")));
}

fn startWithDash(str: []const u8) bool {
    return (str.len > 0) and str[0] == '-';
}

test "startWithDash" {
    try expect(startWithDash("--h") == true);
    try expect(startWithDash("-h") == true);
    try expect(startWithDash("h") == false);
    try expect(startWithDash("") == false);
    try expect(startWithDash(" ") == false);
}

pub fn consumeOsArgs(args: [][]const u8) void {
    _ = args;
}

pub fn main() void {
    info("slice: {s}", .{sliceFromSentinel()});
}

fn sliceFromSentinel() []const u8{
    return "hello";
}

fn optValue() ?i8 {
    return 8;
}

var x: i8 = 8;
fn returnOptErr() ?i8 {
    defer x -= 1;
    if (x == 0) {
        return null;
    }
    return x;
}

