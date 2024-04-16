const std = @import("std");
const windows = @cImport({
    @cInclude("windows.h");
});

fn callback(hwnd: windows.HWND, lparam: windows.LPARAM) callconv(.C) windows.BOOL {
    _ = lparam;
    const length = windows.GetWindowTextLength(hwnd);
    var gpa = std.heap.GeneralPurposeAllocator();
    defer gpa.deinit();
    const allocator = gpa.allocator();

    const buffer = try allocator.alloc(u8, length + 1);
    defer allocator.free(buffer);
    const windowTitle = @as([]const u8, buffer[0..length]);

    std.log.info("{s}\n", .{windowTitle});

    return windows.TRUE;
}

pub fn main() !void {
    const result = windows.EnumWindows(callback, 0);

    std.log.info("{any}\n", .{result});
}
