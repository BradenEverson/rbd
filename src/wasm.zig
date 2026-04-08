//! Wasm Entrypoint

const std = @import("std");
const allocator = std.heap.wasm_allocator;

extern "env" fn log_js(ptr: [*]const u8, len: usize) void;

pub fn log(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const string = std.fmt.bufPrint(&buf, fmt, args) catch @panic("log: formatting failed");
    log_js(string.ptr, string.len);
}

export fn hello() void {
    log("Hello!\n", .{});
}
