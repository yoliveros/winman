const std = @import("std");
const windows = @cImport({
    @cInclude("windows.h");
});

pub const SERVICE_NAME: [*c]u8 = @constCast("ZigService");

fn MessageBoxA(
    hWnd: ?windows.HWND,
    lpText: [*c]const u8,
    lpCaption: [*c]const u8,
    uType: u32,
) callconv(.C) c_int {
    _ = hWnd;
    _ = lpText;
    _ = lpCaption;
    _ = uType;

    return 0;
}

const wm_log = std.log.scoped(.winman);

const state_list = struct {
    pid: []i32,
};

fn callback(hwnd: windows.HWND, lparam: windows.LPARAM) callconv(.C) windows.WINBOOL {
    _ = lparam;
    const length = windows.GetWindowTextLengthA(hwnd);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buffer = allocator.alloc(u8, @intCast(length + 1)) catch unreachable;
    defer allocator.free(buffer);

    const info_buffer = allocator.alloc(windows.WINDOWINFO, 1) catch unreachable;
    defer allocator.free(info_buffer);

    var i: u32 = 0;
    const j: u32 = 0;

    _ = windows.GetWindowThreadProcessId(hwnd, &i);
    _ = windows.GetWindow(hwnd, j);

    _ = windows.GetWindowTextA(hwnd, buffer.ptr, @intCast(buffer.len));

    const text: []const u8 = buffer[0..];

    if (windows.IsWindowVisible(hwnd) == windows.TRUE and length != 0) {
        wm_log.info("buff: {d} {s} {d}\n", .{ j, text, i });
        if (i == 39384) {
            // _ = windows.SetForegroundWindow(hwnd);
        }
    }
    return windows.TRUE;
}

fn ServiceMain(argc: c_ulong, argv: [*c][*c]u8) callconv(.C) void {
    _ = argc;
    _ = argv;
    MessageBoxA(null, "Hello from Zig Windows Service!", "Zig Windows Service", 0);
}

pub fn main() !void {
    // var service_table: [2]windows.SERVICE_TABLE_ENTRYA = undefined;
    // service_table[0] = windows.SERVICE_TABLE_ENTRYA{ .lpServiceName = SERVICE_NAME, .lpServiceProc = ServiceMain };
    // service_table[1] = windows.SERVICE_TABLE_ENTRY{
    //     .lpServiceName = null,
    //     .lpServiceProc = null,
    // };
    //
    // if (windows.StartServiceCtrlDispatcherA(&service_table[0]) == 0) {
    //     const err = windows.GetLastError();
    //     wm_log.warn("StartServiceCtrlDispatcherA failed with error: {}\n", .{err});
    //     return;
    // }
    //
    // const curr_win = windows.GetForegroundWindow();
    //
    // if (curr_win == null) {
    //     wm_log.err("Failed to get current window\n", .{});
    //     return error.GetCurrentWindowFailed;
    // }
    //
    // const length = windows.GetWindowTextLengthA(curr_win);
    //
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    //
    // const buffer = allocator.alloc(u8, @intCast(length + 1)) catch unreachable;
    // defer allocator.free(buffer);
    //
    // var i: u32 = 0;
    //
    // _ = windows.GetWindowTextA(curr_win, buffer.ptr, @intCast(buffer.len));
    // _ = windows.GetWindowThreadProcessId(curr_win, &i);
    //
    // wm_log.info("pid: {d}, title: {s}\n", .{ i, buffer });

    // var char: u8 = undefined;
    // const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    // const key_state = enum(i8) {
    //     dfault = 0,
    //     up = 1,
    //     down = -127,
    //     toggle = -128,
    // };

    while (true) {
        const key: i16 = windows.GetAsyncKeyState(windows.VK_LMENU);

        if (key < 0) {
            if (key == 'a') {
                // state_list = .{ .pid = &[_]i32{39384} };
            }

            try stdout.writeAll("down\n");
        }
    }
}
