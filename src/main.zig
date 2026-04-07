const std = @import("std");
const rbd = @import("rbd.zig");

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

    var lines = std.mem.tokenizeAny(u8, data, "\n");
    var diagram = try parseNode(alloc, &lines);
    defer diagram.deinit(alloc);

    std.debug.print("Reliability: {:.2}%\n", .{diagram.getReliability() * 100});
}

const ParseError = error{
    EmptyFile,
    ImproperArgs,
    UnknownNodeType,
};

const AllParseErrors = ParseError || std.fmt.ParseFloatError || std.fmt.ParseIntError || std.mem.Allocator.Error;

fn parseNode(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any)) AllParseErrors!rbd.BlockNode {
    const line = lines.next() orelse return error.EmptyFile;
    const stripped = std.mem.trim(u8, line, " \t");

    var args = std.mem.tokenizeAny(u8, stripped, " \t");

    const node_type = args.next() orelse return error.ImproperArgs;
    const node_arg = args.next() orelse return error.ImproperArgs;

    if (std.mem.eql(u8, node_type, "series")) {
        const count = try std.fmt.parseInt(usize, node_arg, 10);
        return parseSeries(alloc, lines, count);
    } else if (std.mem.eql(u8, node_type, "parallel")) {
        const count = try std.fmt.parseInt(usize, node_arg, 10);
        return parseParallel(alloc, lines, count);
    } else if (std.mem.eql(u8, node_type, "mod")) {
        const reliabilty = try std.fmt.parseFloat(f32, node_arg);

        return .{ .module = reliabilty };
    } else {
        return error.UnknownNodeType;
    }
}

fn parseSeries(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any), count: usize) !rbd.BlockNode {
    var series = rbd.Series{};

    for (0..count) |_| {
        var node = try parseNode(alloc, lines);
        errdefer node.deinit(alloc);

        try series.add(alloc, node);
    }

    return .{ .series = series };
}

fn parseParallel(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any), count: usize) !rbd.BlockNode {
    var parallel = rbd.Parallel{};

    for (0..count) |_| {
        var node = try parseNode(alloc, lines);
        errdefer node.deinit(alloc);

        try parallel.add(alloc, node);
    }

    return .{ .parallel = parallel };
}
