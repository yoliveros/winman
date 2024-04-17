const std = @import("std");
const windows = @cImport({
    @cInclude("windows.h");
});

const wm_log = std.log.scoped(.winman);

fn callback(hwnd: windows.HWND, lparam: windows.LPARAM) callconv(.C) windows.WINBOOL {
    _ = lparam;
    const length = windows.GetWindowTextLengthA(hwnd);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buffer = allocator.alloc(u8, @intCast(length + 1)) catch unreachable;
    defer allocator.free(buffer);

    _ = windows.GetWindowTextA(hwnd, buffer.ptr, @intCast(buffer.len));

    const text: []const u8 = buffer[0..];

    if (windows.IsWindowVisible(hwnd) == windows.TRUE and length != 0) {
        wm_log.info("buff: {*} {d} {s}\n", .{ buffer.ptr, buffer.len, text });
    }
    return windows.TRUE;
}

pub fn main() !void {
    wm_log.info("Enumerating windows...\n", .{});
    const result = windows.EnumWindows(callback, 0);

    if (result == windows.FALSE) {
        wm_log.err("Failed to enumerate windows\n", .{});
        return error.EnumerateWindowsFailed;
    }
}
