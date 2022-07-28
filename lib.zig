const std = @import("std");
const print = std.debug.print;
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

pub fn keyValueFromArgs(args: [][*:0]const u8) !std.StringHashMap([]const u8) {
    // TODO: allow allocator to be passed in
    var key_value = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    var os_args_consumer = ArgsConsumer{.args = args};
    while (try os_args_consumer.consume()) |result| {
        try key_value.put(result.key, result.value);
    }
    return key_value;
}

const KeyValue = struct {
    key: []const u8,
    value: []const u8,
};

const ArgsConsumer = struct {
    args: [][*:0]const u8,

    fn popFromStart(self: *ArgsConsumer) ?[]const u8 {
        const result = self.peekFromStart();
        if (result != null) {
            self.args = self.args[1..];
        }
        return result;
    }

    fn peekFromStart(self: ArgsConsumer) ?[]const u8 {
        if (self.args.len == 0) {
            return null;
        }
        return std.mem.span(self.args[0]);
    }

    fn consume(self: *ArgsConsumer) !?KeyValue {
        var next = self.popFromStart() orelse return null;

        if (startWithDash(next)) {
            next = trimDash(next);
        } else {
            std.log.err("invalid argument name found: {s}", .{next});
            return error.InvalidArgs; // TODO: Pass value with error when possible
        }

        if (getEqualityKeyValue(next)) |result| {
            return result;
        }

        const next2 = self.peekFromStart() orelse return KeyValue{.key = next, .value = ""};
        if (startWithDash(next2)) {
            return KeyValue{.key = next, .value = ""};
        }

        self.args = self.args[1..];
        return KeyValue{.key = next, .value = next2};
    }
};

fn getEqualityKeyValue(str: []const u8) ?KeyValue {
    for (str) |b, i| {
        if (b == '=') {
            return KeyValue {
                .key = str[0..i],
                .value = str[i+1..],
            };
        }
    }
    return null;
}

test "getEqualityKeyValue" {
    try expect(getEqualityKeyValue("hello") == null);
    try expect(getEqualityKeyValue("") == null);

    const kv: KeyValue = getEqualityKeyValue("hello=world").?;
    try expect(mem.eql(u8, kv.key, @as([]const u8, "hello")));
    try expect(mem.eql(u8, kv.value, @as([]const u8, "world")));

    const kv2: KeyValue = getEqualityKeyValue("hello=").?;
    try expect(mem.eql(u8, kv2.key, @as([]const u8, "hello")));
    try expect(mem.eql(u8, kv2.value, @as([]const u8, "")));

    const kv3: KeyValue = getEqualityKeyValue("=world").?;
    try expect(mem.eql(u8, kv3.key, @as([]const u8, "")));
    try expect(mem.eql(u8, kv3.value, @as([]const u8, "world")));
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

pub fn main() !void {
    var args = [_][*:0]const u8{"--hello", "world"};
    var args_ptr: [][*:0]const u8 = &args;
    var kv: std.StringHashMap([]const u8) = try keyValueFromArgs(args_ptr);
    const value = kv.get("hello").?;
    print("value from hello key: {s}", .{value});
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

