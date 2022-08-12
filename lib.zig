// TODO: Bash completion
// TODO: Man Page
// TODO: Help Message Generation

const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const expect = std.testing.expect;
const expectError = std.testing.expectError;
const info = std.log.info;

// example args:    ./program_name --name zx --number 2 -- search
// returns:         --name zx --number 2 -- search
pub fn getOsArgs() [][*:0]const u8 {
    const args: [][*:0]const u8 = std.os.argv;
    return args[1..];
}

pub fn Flag(comptime T: type) type {
    return struct {
        const Self = @This();

        name: []const u8,
        parse_func: fn (?[]const u8) anyerror!T,
        default: ?T = null,
        alias: ?[]const u8 = null,
        desc: ?[]const u8 = null,

        pub fn init(self: Self) Self {
            //TODO:
            // init should take in compulsory stuff
            // check for Duplicated name and alias
            // add to list of help message (TODO)
            return self;
        }

        pub fn valueFromMap(self: Self, key_value: std.StringHashMap(?[]const u8)) anyerror!?T {
            const opt_named_value = key_value.get(self.name);
            const opt_aliased_value = blk: {
                if (self.alias) |alias_name| {
                    break :blk key_value.get(alias_name);
                } else {
                    break :blk null;
                }
            };

            if (opt_named_value) |named_value| {
                if (opt_aliased_value) |aliased_value| {
                    _ = aliased_value;
                    // std.log.err("Ambiguous value: both name and alias are present, name:{s}, alias:{s}", .{named_value, aliased_value});
                    return error.AmbiguousValue;
                }
                return try self.parse_func(named_value);
            }

            if (opt_aliased_value) |aliased_value| {
                return try self.parse_func(aliased_value);
            }

            return self.default;
        }
    };
}

const ParseResult = struct {
    // key_value represents the parsed result from e.g.:
    // --name hello --line 12
    key_value: std.StringHashMap(?[]const u8),

    // represents remaining args after --
    // e.g. ./program_name --name zx --number 2 -- param1 param2
    params: [][*:0]const u8,
};

// TODO:
// return helpful messages when parsing fail, maybe wait for error with values
// wait for errors with value?
// return the rest of the args after - or --
// wait for tuples with multiple return values?
pub fn parseArgs(allocator: std.mem.Allocator, args: [][*:0]const u8) !ParseResult {
    var key_value = std.StringHashMap(?[]const u8).init(allocator);
    var os_args_consumer = ArgsConsumer{ .args = args };

    while (try os_args_consumer.consume()) |result| {
        if (key_value.getKey(result.key)) |key| {
            std.log.err("duplicated args found: {s}\n", .{key});
            return error.DuplicatedArguments;
        }
        try key_value.put(result.key, result.value);
    }

    return ParseResult{
        .key_value = key_value,
        .params = os_args_consumer.args,
    };
}

const KeyValue = struct {
    key: []const u8,
    value: ?[]const u8,
};

const ArgsConsumer = struct {
    args: [][*:0]const u8,

    fn popFromStart(self: *ArgsConsumer) ?[]const u8 {
        if (self.peekFromStart()) |value| {
            self.args = self.args[1..];
            return value;
        }
        return null;
    }

    fn peekFromStart(self: ArgsConsumer) ?[]const u8 {
        if (self.args.len == 0) {
            return null;
        }
        return std.mem.span(self.args[0]);
    }

    fn consume(self: *ArgsConsumer) !?KeyValue {
        var next = self.popFromStart() orelse return null;
        if (!startWithDash(next)) {
            return error.InvalidArgs; // TODO: Pass value with error when possible
        }

        // since we have already determine that it starts with '-'
        // we don't need to check the first elem againt
        next = trimDash(next[1..]);

        // Scenario:
        // ./program_name --name zx --number 2 -- search
        //                                     ^^ indicates end of args
        if (next.len == 0) {
            return null;
        }

        if (getEqualityKeyValue(next)) |result| {
            return result;
        }

        const next2 = self.peekFromStart() orelse return KeyValue{ .key = next, .value = null };
        if (startWithDash(next2)) {
            return KeyValue{ .key = next, .value = null };
        }

        self.args = self.args[1..];
        return KeyValue{ .key = next, .value = next2 };
    }
};

// typical full name arg parse
test "parseArgs 1" {
    var args = [_][*:0]const u8{ "--hello", "world" };
    const res: ParseResult = try parseArgs(std.heap.page_allocator, &args);
    const value = res.key_value.get("hello").?;
    try expect(std.mem.eql(u8, value.?, "world"));
}

// with single dash
test "parseArgs 2" {
    var args = [_][*:0]const u8{ "-h", "world" };
    const res: ParseResult = try parseArgs(std.heap.page_allocator, &args);
    const value = res.key_value.get("h").?;
    try expect(std.mem.eql(u8, value.?, "world"));
}

// with next args as blank
test "parseArgs 3" {
    var args = [_][*:0]const u8{ "-h", " " };
    const res: ParseResult = try parseArgs(std.heap.page_allocator, &args);
    const value = res.key_value.get("h").?;
    try expect(std.mem.eql(u8, value.?, " "));
}

// with no value
test "parseArgs 4" {
    var args = [_][*:0]const u8{ "-h", "-l" };
    const res = try parseArgs(std.heap.page_allocator, &args);
    const h_value = res.key_value.get("h").?;
    try expect(h_value == null);
    const l_value = res.key_value.get("l").?;
    try expect(l_value == null);
}

// with terminating - or --
test "parseArgs 5" {
    // std.testing.log_level = std.log.Level.info;
    var args = [_][*:0]const u8{ "--number", "1", "--lines", "2", "--", "my_path", "another_arg" };
    // info("args: {s}", .{args});
    const res = try parseArgs(std.heap.page_allocator, &args);
    const num = res.key_value.get("number").?;
    try expect(std.mem.eql(u8, num.?, "1"));
    const ln = res.key_value.get("lines").?;
    try expect(std.mem.eql(u8, ln.?, "2"));
}

test "parseArgs 6" {
    // expected to fail
    var args = [_][*:0]const u8{ "hello", " " };
    try expectError(error.InvalidArgs, parseArgs(std.heap.page_allocator, &args));
}

test "parseArgs 7" {
    // parse with params
    // std.testing.log_level = std.log.Level.info;
    var args = [_][*:0]const u8{ "--hello", "world", "--debug", "--", "search", "." };
    const res = try parseArgs(std.heap.page_allocator, &args);
    const params = res.params;
    // std.log.info("params: {s}",.{params[0]});
    // std.log.info("params: {s}",.{@TypeOf(params[0])});

    try expect(std.mem.eql(u8, std.mem.span(params[0]), "search"));
    try expect(std.mem.eql(u8, std.mem.span(params[1]), "."));
}

fn getEqualityKeyValue(str: []const u8) ?KeyValue {
    for (str) |b, i| {
        if (b == '=') {
            return KeyValue{
                .key = str[0..i],
                .value = str[i + 1 ..],
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
    try expect(mem.eql(u8, kv.value.?, @as([]const u8, "world")));

    const kv2: KeyValue = getEqualityKeyValue("hello=").?;
    try expect(mem.eql(u8, kv2.key, @as([]const u8, "hello")));
    try expect(mem.eql(u8, kv2.value.?, @as([]const u8, "")));

    const kv3: KeyValue = getEqualityKeyValue("=world").?;
    try expect(mem.eql(u8, kv3.key, @as([]const u8, "")));
    try expect(mem.eql(u8, kv3.value.?, @as([]const u8, "world")));
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
