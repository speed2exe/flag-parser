const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    // comptime {
    //     var myCar: Car = Car.init("honda");

    //     @compileLog(myCar.brand);
    // }

    const a: ??[]const u8 = null;
    if (a == null) {
        print("is null: {s}", .{a});
    }
}

const Car = struct {
    brand: []const u8,
    plate_number: u64 = 1,

    pub fn init(brand: []const u8) Car {
        return Car{
            .brand = brand,
        };
    }

    pub fn setPlate(c: *Car, new_value: u64) Car {
        c.plate_number = new_value;
        return c.*;
    }
};
