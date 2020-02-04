const std = @import("std");

pub fn order(comptime T: type, lhs: []const T, rhs: []const T) std.math.Order {
    const n = std.math.min(lhs.len, rhs.len);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        switch (std.math.order(lhs[i], rhs[i])) {
            .eq => continue,
            .lt => return .lt,
            .gt => return .gt,
        }
    }
    return std.math.order(lhs.len, rhs.len);
}

pub fn orderUsize(comptime T: type, lhs: []const T, rhs: []const T) std.math.Order {
    const usize_bytes = @sizeOf(usize);
    const n = std.math.min(lhs.len, rhs.len);
    var i: usize = 0;
    while ((i + 1) * usize_bytes < n) : (i += usize_bytes) {
        const a = std.mem.readIntBig(usize, @ptrCast(*const [usize_bytes]u8, &lhs[i]));
        const b = std.mem.readIntBig(usize, @ptrCast(*const [usize_bytes]u8, &rhs[i]));
        switch (std.math.order(a, b)) {
            .eq => continue,
            .lt => return .lt,
            .gt => return .gt,
        }
    }
    while (i < n) : (i += 1) {
        switch (std.math.order(lhs[i], rhs[i])) {
            .eq => continue,
            .lt => return .lt,
            .gt => return .gt,
        }
    }
    return std.math.order(lhs.len, rhs.len);
}

const bench = @import("bench.zig");
test "benchmark" {
    try bench.benchmark(struct {
        const Arg = struct {
            lhs: []const u8,
            rhs: []const u8,

            fn bench(a: Arg, func: var) void {
                _ = func(u8, a.lhs, a.rhs);
            }
        };

        const rand = @embedFile("rand.txt");

        pub const args = [_]Arg{
            .{ .lhs = "abc", .rhs = "abd" },
            .{ .lhs = "abcdefghijklmnopqrstuvwxyz", .rhs = "Xbcdefghijklmnopqrstuvwxyz" },
            .{ .lhs = "abcdefghijklmnopqrstuvwxyz", .rhs = "abcdefghijklXnopqrstuvwxyz" },
            .{ .lhs = "abcdefghijklmnopqrstuvwxyz", .rhs = "abcdefghijklmnopqrstuvwxyz" },
            .{ .lhs = rand, .rhs = rand },
        };

        pub const iterations = 100000;

        pub fn @"-----"(a: Arg) void {
            a.bench(order);
        }

        pub fn base(a: Arg) void {
            a.bench(order);
        }

        pub fn improved(a: Arg) void {
            a.bench(orderUsize);
        }
    });
}
