//! Parsing from string format to an RBD

const std = @import("std");
const rbd = @import("rbd.zig");

pub const ParseError = error{
    EmptyFile,
    ImproperArgs,
    UnknownNodeType,
};

pub const AllParseErrors = ParseError || std.fmt.ParseFloatError || std.fmt.ParseIntError || std.mem.Allocator.Error;

pub fn parseSerializedRbd(alloc: std.mem.Allocator, data: []const u8) !rbd.BlockNode {
    var lines = std.mem.tokenizeAny(u8, data, "\n");
    return parseNode(alloc, &lines, 0);
}

fn isWhitespace(char: u8) bool {
    return (char == ' ') or (char == '\t');
}

fn parseNode(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any), level: usize) AllParseErrors!rbd.BlockNode {
    const line = lines.next() orelse return error.EmptyFile;
    var args = std.mem.tokenizeAny(u8, line[level..], " \t");

    const node_type = args.next() orelse return error.ImproperArgs;

    if (std.mem.eql(u8, node_type, "series")) {
        return parseSeries(alloc, lines, level);
    } else if (std.mem.eql(u8, node_type, "parallel")) {
        return parseParallel(alloc, lines, level);
    } else if (std.mem.eql(u8, node_type, "mod")) {
        const node_arg = args.next() orelse return error.ImproperArgs;
        const reliabilty = try std.fmt.parseFloat(f32, node_arg);

        return .{ .module = reliabilty };
    } else {
        return error.UnknownNodeType;
    }
}

fn parseSeries(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any), level: usize) !rbd.BlockNode {
    var series = rbd.Series{};

    while (lines.peek() != null and isWhitespace(lines.peek().?[level])) {
        var node = try parseNode(alloc, lines, level + 1);
        errdefer node.deinit(alloc);

        try series.add(alloc, node);
    }

    return .{ .series = series };
}

fn parseParallel(alloc: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .any), level: usize) !rbd.BlockNode {
    var parallel = rbd.Parallel{};

    while (lines.peek() != null and isWhitespace(lines.peek().?[level])) {
        var node = try parseNode(alloc, lines, level + 1);
        errdefer node.deinit(alloc);

        try parallel.add(alloc, node);
    }

    return .{ .parallel = parallel };
}
