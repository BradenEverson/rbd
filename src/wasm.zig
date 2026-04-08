//! Wasm Entrypoint

const parser = @import("parser.zig");
const std = @import("std");
const allocator = std.heap.wasm_allocator;

extern "env" fn log_js(ptr: [*]const u8, len: usize) void;

pub fn log(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const string = std.fmt.bufPrint(&buf, fmt, args) catch @panic("log: formatting failed");
    log_js(string.ptr, string.len);
}

export fn alloc(len: usize) [*]u8 {
    const buf = allocator.alloc(u8, len) catch @panic("out of memory");
    return buf.ptr;
}

export fn free(ptr: [*]u8, len: usize) void {
    allocator.free(ptr[0..len]);
}

export fn buildRbdAndEval(str: [*]u8, len: usize) f32 {
    const data: []const u8 = str[0..len];
    defer allocator.free(data);

    var graph = parser.parseSerializedRbd(allocator, data) catch |err| {
        log("Building RBG Failed!\nError: {any}\n", .{err});
        return -1.0;
    };
    defer graph.deinit(allocator);

    return graph.getReliability();
}
