const std = @import("std");
const print = std.debug.print;
const lib = @import("./lib.zig");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub fn main() !void {
    // Examples with two flags:

    // Parse os arguments into kv
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, lib.getOsArgs());

    // Declare the args:
    // TODO: ensure that each flag declared is not duplicated, name or alias, throw error during comptime
    const err_opt_num = (lib.Flag(i8){.name = "number", .parse_func = parsei8}).init().valueFromMap(kv);
    const line = (lib.Flag(i8){.name = "line", .parse_func = parsei8}).init().valueFromMap(kv);
    // With Error Checking:
    // const num = try (lib.Flag(i8){.name = "number", .parse_func = parsei8}).valueFromMap(kv);
    // const line = try (lib.Flag(i8){.name = "line", .parse_func = parsei8}).valueFromMap(kv);

    // handling of the variable
    if (err_opt_num) |opt_num| {
        if (opt_num) |num| {
            print("number: {}, type: {}\n", .{num,@TypeOf(num)});
        } else {
            print("number is null ",.{});
        }
    } else |err| {
        print("got error while attempting to get value of number arg: {}",.{err});
    }

    // debug your arg 
    print("\nline: {}, type: {}\n", .{line,@TypeOf(line)});

    

    // TODO: experiment with comptime stuff
}

fn myFunc() struct{a: i8, b: u8} {
    return .{.a = 8, .b = 8};
}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}

fn failedParsei8(str: []const u8) !i8 {
    _ = str;
    return error.ParseError;
}

test "lib single args" {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = parsei8};
    var args = [_][*:0]const u8{"--number", "117"};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 117);
}

test "lib double args" {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = parsei8};
    const line_flag = lib.Flag(i8){.name = "line", .parse_func = parsei8};

    var args = [_][*:0]const u8{"--number", "117", "-line", "85"};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    var value1 = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value1.? == 117);
    var value2 = line_flag.valueFromMap(kv) catch unreachable;
    try expect(value2.? == 85);
}

test "lib single alias" {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = parsei8};
    var args = [_][*:0]const u8{"--num", "117"};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 117);
}

test "lib no args" {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = parsei8};
    var args = [_][*:0]const u8{};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value == null);
}

test "lib with default" {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = parsei8, .default = 88};
    var args = [_][*:0]const u8{};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    var value = num_flag.valueFromMap(kv) catch unreachable;
    try expect(value.? == 88);
}

test "lib with erronous parsing " {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = failedParsei8, .default = 88};
    var args = [_][*:0]const u8{"--num", "125"};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    try expectError(error.ParseError, num_flag.valueFromMap(kv));
}

test "lib with both named and alias parsing " {
    const num_flag = lib.Flag(i8){.name = "number", .alias = "num", .parse_func = failedParsei8, .default = 88};
    var args = [_][*:0]const u8{"--num", "125", "--number", "126"};
    const kv = try lib.keyValueFromArgs(std.heap.page_allocator, &args);
    try expectError(error.AmbiguousValue, num_flag.valueFromMap(kv));
}
