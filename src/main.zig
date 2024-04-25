const std = @import("std");
const windows = @cImport({
    @cInclude("windows.h");
});

var service_status: windows.SERVICE_STATUS = undefined;
var h_status: windows.SERVICE_STATUS_HANDLE = undefined;

const SERVICE_NAME = "WinMan";

const wm_log = std.log.scoped(.winman);

const state_list = struct {
    pid: []i32,
};

fn serviceMain(argc: c_ulong, argv: [*c][*c]u8) callconv(.C) void {
    _ = argc;
    _ = argv;
    service_status.dwServiceType = windows.SERVICE_WIN32;
    service_status.dwCurrentState = windows.SERVICE_START_PENDING;
    service_status.dwControlsAccepted = windows.SERVICE_ACCEPT_STOP | windows.SERVICE_ACCEPT_SHUTDOWN;
    service_status.dwWin32ExitCode = 0;
    service_status.dwServiceSpecificExitCode = 0;
    service_status.dwCheckPoint = 0;
    service_status.dwWaitHint = 0;

    h_status = windows.RegisterServiceCtrlHandlerExA(
        SERVICE_NAME,
        @as(windows.LPHANDLER_FUNCTION_EX, controlHandler),
        null,
    );

    run();
}

fn controlHandler(request: windows.DWORD, _: windows.DWORD, _: windows.LPVOID, _: windows.LPVOID) callconv(.C) windows.DWORD {
    switch (request) {
        windows.SERVICE_CONTROL_STOP => {
            service_status.dwCurrentState = windows.SERVICE_STOP;
            service_status.dwWin32ExitCode = 0;

            _ = windows.SetServiceStatus(h_status, &service_status);
            return 0;
        },
        windows.SERVICE_CONTROL_SHUTDOWN => {
            service_status.dwCurrentState = windows.SERVICE_STOP;
            service_status.dwWin32ExitCode = 0;

            _ = windows.SetServiceStatus(h_status, &service_status);
            return 0;
        },
        else => {},
    }

    _ = windows.SetServiceStatus(h_status, &service_status);

    return 0;
}

fn run() callconv(.C) void {
    service_status.dwCurrentState = windows.SERVICE_RUNNING;
    _ = windows.SetServiceStatus(h_status, &service_status);

    // const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    const curr_win = windows.GetForegroundWindow();

    if (curr_win == null) {
        wm_log.err("Failed to get current window\n", .{});
        return;
    }

    const length = windows.GetWindowTextLengthA(curr_win);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const buffer = allocator.alloc(u8, @intCast(length + 1)) catch unreachable;
    defer allocator.free(buffer);

    var i: u32 = 0;

    _ = windows.GetWindowTextA(curr_win, buffer.ptr, @intCast(buffer.len));
    _ = windows.GetWindowThreadProcessId(curr_win, &i);

    var file = std.fs.cwd().createFile("test.txt", .{ .read = true }) catch unreachable;
    defer file.close();

    file.writeAll(buffer) catch unreachable;
    while (service_status.dwCurrentState == windows.SERVICE_RUNNING) {
        const key: i16 = windows.GetAsyncKeyState(windows.VK_LMENU);

        if (key < 0) {
            if (key == 'a') {
                // state_list = .{ .pid = &[_]i32{39384} };
            }

            stdout.writeAll("down\n") catch unreachable;
        }
    }
}

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

pub fn main() !void {
    var service_table = [_]windows.SERVICE_TABLE_ENTRY{
        .{ .lpServiceName = @constCast(SERVICE_NAME), .lpServiceProc = serviceMain },
        .{ .lpServiceName = null, .lpServiceProc = null },
    };

    _ = windows.StartServiceCtrlDispatcherA(&service_table[0]);
}
