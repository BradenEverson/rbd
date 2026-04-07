const std = @import("std");
const rbd = @import("rbd.zig");
const parser = @import("parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    var args = std.process.args();
    _ = args.skip();

    var data: []u8 = undefined;
    if (args.next()) |file_path| {
        data = std.fs.cwd().readFileAlloc(alloc, file_path, 65536) catch {
            std.debug.print("Error: File does not exist!\n", .{});
            std.process.exit(1);
        };
    } else {
        std.debug.print("Usage: ./rbd file.rbd\n", .{});
        std.process.exit(1);
    }
    defer alloc.free(data);

    var diagram = try parser.parseSerializedRbd(alloc, data);
    defer diagram.deinit(alloc);

    std.debug.print("Reliability: {:.2}%\n", .{diagram.getReliability() * 100});
}
