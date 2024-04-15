const std = @import("std");
const windows = @cImport({
    @cInclude("windows.h");
});

pub fn main() !void {
    _ = windows.GetModuleHandleW(null);
    std.debug.print("Hello, world!\n", .{});
}
