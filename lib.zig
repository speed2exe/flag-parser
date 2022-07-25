const std = @import("std");

// add default value based on type field
pub fn FlagOf(comptime T: type) type {
    return struct {
        const Self = @This();

        name:      []const u8,
        parseFunc: fn([]const u8) anyerror!T,
        default:   ?T                       = null,
        alias:     ?[]const u8              = null,
        desc:      ?[]const u8              = null,

        pub fn init(self: Self) FlagResult(T) {
            return FlagResult(T){
                .parseFunc = self.parseFunc,
            };
        }
    };
}

// Need to test
fn FlagResult(comptime T: type) type {
    return struct {
        const Self = @This();

        strValue: ?[]const u8 = null,
        parseFunc : fn([]const u8) anyerror!T,
        evaluated: bool = false,
        value: anyerror!?T = null,

        pub fn eval(self: *Self) anyerror!?T {
            if (self.evaluated) {
                return self.value;
            }
            defer {
                self.evaluated = true;
            }
            var str: []const u8 = self.strValue orelse return null;
            const parsed: T = try self.parseFunc(str);
            defer {
                self.value = parsed;
            }
            return @as(anyerror!?T, parsed);
        }

        // need a funtion to register with os orgs,
        // so that the strValue can be set when initialized
    };
}

fn parsei8(str: []const u8) !i8 {
    return std.fmt.parseInt(i8, str, 10);
}

test "test FlagResult 1" {
    var flag_result = FlagResult(i8) {
        .strValue = "9",
        .parseFunc = parsei8,
        .evaluated = false,
        .value = null,
    };

    const optValue = try flag_result.eval();
    const value: i8 = optValue orelse unreachable;
    

    try std.testing.expect(value == @as(i8, 9));
    try std.testing.expect(flag_result.evaluated == true);
    const flagValOpt: ?i8 = flag_result.value catch unreachable;
    const flagVal: i8 = flagValOpt orelse unreachable;
    try std.testing.expect(flagVal == @as(i8, 9));
}


// Provided by flag so that when args is parsed, the registered flag will 
// automatically assigned the string(not yet parsed)
// TODO: investigate into comptime hashmap, for now just do simple loop
// Behavior: if multiple args with same name is set, it will only apply the latest
const registration = struct {
    alias: []const u8,
    name: []const u8,
    setFunc: fn([]const u8) void,
};

var os_kv_map: OsArgsKV = undefined;

const OsArgsKV = struct {

    // e.g. some_app -n 12 => n is the key, 12 is the value to be passed in to
    // the set_func
    set_func_by_arg: std.HashMap([]const u8, fn([]const u8)void),
    
    // TODO: stored unmapped values??

    pub fn init() void {
        // get all args from os program args 
        // iterate, if exists, set the value using set_func
    }

};
