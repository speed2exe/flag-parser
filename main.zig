const std = @import("std");
const print = std.debug.print;
const lib = @import("./lib.zig");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub fn main() !void {
    // Examples with two flags:

    // Parse os arguments into kv
    const res = try lib.parseArgs(std.heap.page_allocator, lib.getOsArgs());
    const kv = res.key_value;

    // Declare the args:
    const err_opt_num = (lib.Flag(i8){ .name = "number", .parse_func = parsei8 }).init().valueFromMap(kv);
    const line = (lib.Flag(i8){ .name = "line", .parse_func = parsei8 }).init().valueFromMap(kv);
    const ignore_hidden = (lib.Flag(i8){ .name = "ignore_hidden", .parse_func = parseBool }).init().valueFromMap(kv);

    // With Error Checking:
    // const num = try (lib.Flag(i8){.name = "number", .parse_func = parsei8}).valueFromMap(kv);
    // const line = try (lib.Flag(i8){.name = "line", .parse_func = parsei8}).valueFromMap(kv);

    // handling of the variable
    if (err_opt_num) |opt_num| {
        if (opt_num) |num| {
            print("number: {}, type: {}\n", .{ num, @TypeOf(num) });
        } else {
            print("number is null ", .{});
        }
    } else |err| {
        print("got error while attempting to get value of number arg: {}", .{err});
    }

    // debug your arg
    print("\nline: {}, type: {}\n", .{ line, @TypeOf(line) });
    print("\nignore_hidden: {}, type: {}\n", .{ ignore_hidden, @TypeOf(ignore_hidden) });

    // TODO: experiment with comptime stuff
}

fn myFunc() struct { a: i8, b: u8 } {
    return .{ .a = 8, .b = 8 };
}

fn parsei8(str: ?[]const u8) !i8 {
    // treat ? as null string
    const final_str = str orelse "";
    return std.fmt.parseInt(i8, final_str, 10);
}

fn failedParsei8(str: ?[]const u8) !i8 {
    _ = str;
    return error.ParseError;
}

fn parseBool(str: ?[]const u8) !bool {
    // set value to true when no value is provided
    // e.g. ./program_name --debug
    //                              => debug is  set to true
    const bool_str = str orelse {
        return true;
    };

    return ((std.mem.eql(u8, bool_str, @as([]const u8, "0"))) and
        (std.mem.eql(u8, bool_str, @as([]const u8, "false"))) and
        (std.mem.eql(u8, bool_str, @as([]const u8, "FALSE"))));
}

test "lib single args" {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = parsei8 };
    var args = [_][*:0]const u8{ "--number", "117" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 117);
}

test "lib double args" {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = parsei8 };
    const line_flag = lib.Flag(i8){ .name = "line", .parse_func = parsei8 };

    var args = [_][*:0]const u8{ "--number", "117", "-line", "85" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var value1 = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value1.? == 117);
    var value2 = line_flag.valueFromMap(kv) catch unreachable;
    try expect(value2.? == 85);
}

test "lib single alias" {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = parsei8 };
    var args = [_][*:0]const u8{ "--num", "117" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 117);
}

test "lib no args" {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = parsei8 };
    var args = [_][*:0]const u8{};
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value == null);
}

test "lib args with boolean args" {
    const is_dead = lib.Flag(bool){ .name = "is_dead", .parse_func = parseBool };
    const is_lucky = lib.Flag(bool){ .name = "is_lucky", .parse_func = parseBool };
    const is_happy = lib.Flag(bool){ .name = "is_happy", .parse_func = parseBool };
    var args = [_][*:0]const u8{ "--is_dead", "--is_lucky", "false", "--is_happy" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var is_dead_value = is_dead.valueFromMap(kv) catch unreachable;
    try expect(is_dead_value.? == true);
    var is_lucky_value = is_lucky.valueFromMap(kv) catch unreachable;
    try expect(is_lucky_value.? == false);
    var is_happy_value = is_happy.valueFromMap(kv) catch unreachable;
    try expect(is_happy_value.? == true);
}

test "lib with default" {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = parsei8, .default = 88 };
    var args = [_][*:0]const u8{};
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 88);
}

test "lib with erronous parsing " {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = failedParsei8, .default = 88 };
    var args = [_][*:0]const u8{ "--num", "125" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    try expectError(error.ParseError, num_flag.valueFromMap(kv));
}

test "lib with both named and alias parsing " {
    const num_flag = lib.Flag(i8){ .name = "number", .alias = "num", .parse_func = failedParsei8, .default = 88 };
    var args = [_][*:0]const u8{ "--num", "125", "--number", "126" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const kv = res.key_value;
    try expectError(error.AmbiguousValue, num_flag.valueFromMap(kv));
}

test "lib with params after args" {
    var args = [_][*:0]const u8{ "--num", "125", "--", "hello" , "world" };
    const res = try lib.parseArgs(std.heap.page_allocator, &args);
    const params = res.params;
    try expect(std.mem.eql(u8, std.mem.span(params[0]), "hello"));
    try expect(std.mem.eql(u8, std.mem.span(params[1]), "world"));
}
