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
    var os_args_consumer = ArgsConsumer{};
    while (try os_args_consumer.consume()) |result| {
        osKeyValue.put(result.key, result.value);
    }
    return osKeyValue;
}

fn slicessOfSentinelStrs(strs: [][*:0]u8) [][]const u8 {
    const result: [][]const u8 = [strs.len][].{};
    return result;
}

const KeyValue = struct {
    key: []const u8,
    value: []const u8,
};

const ArgsConsumer = struct {
    args: [][]const u8,

    fn popFromStart(self: *ArgsConsumer) ?[]const u8 {
        const result = self.peekFromStart();
        if (result) {
            self.args = self.args[1..];
        }
        return result;
    }

    fn peekFromStart(self: ArgsConsumer) ?[]const u8 {
        if (self.args.len == 0) {
            return null;
        }
        return self.args[0];
    }

    fn consume(self: *ArgsConsumer) !?KeyValue {
        const next = self.popFromStart() orelse return null;

        if (startWithDash(next)) {
            next = trimDash(next);
        } else {
            std.log.err("invalid argument name found: {}", next);
            return error.InvalidArgs; // TODO: Pass value with error when possible
        }

        if (getEqualityKeyValue()) |result| {
            return result;
        }

        const next2 = peekFromStart() orelse return KeyValue{.key = next, .value = ""};
        if (startWithDash(next2)) {
            KeyValue{.key = next, .value = ""};
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

pub fn consumeOsArgs(args: [][]const u8) void {
    _ = args;
}

pub fn main() void {
    var array = [_][*:0]const u8{"hello", "world", "foo", "bar"};
    // const slice: [][*:0]const u8 = &array;

    var result: [array.len][]const u8 = undefined;
    for (array) |str, i| {
        result[i] = str;
    }

    info("result: {s}", .{result});

    // info("slice: {s}", .{slice});
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

