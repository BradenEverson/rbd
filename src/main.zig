const std = @import("std");
const rbd = @import("rbd.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const A = rbd.BlockNode{ .module = 0.96 };
    const B = rbd.BlockNode{ .module = 0.92 };
    const C = rbd.BlockNode{ .module = 0.99 };

    var AB_series = rbd.Series{};
    defer AB_series.deinit(alloc);

    try AB_series.add(alloc, A);
    try AB_series.add(alloc, B);

    var AB_par = rbd.Parallel{};
    defer AB_par.deinit(alloc);

    try AB_par.add(alloc, rbd.BlockNode{ .series = AB_series });
    try AB_par.add(alloc, rbd.BlockNode{ .series = AB_series });

    var graph_series = rbd.Series{};
    defer graph_series.deinit(alloc);

    try graph_series.add(alloc, rbd.BlockNode{ .parallel = AB_par });
    try graph_series.add(alloc, C);

    const graph = rbd.BlockNode{ .series = graph_series };

    std.debug.print("Reliability: {}\n", .{graph.getReliability() * 100});
}
