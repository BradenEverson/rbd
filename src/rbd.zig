//! Reliability Block Diagram high level graph
//! A node can either be a series, parallel, or root module with a fixed reliability
//!
//! - series reliability is the product of all module reliabilities in the system
//! - parallel is 1 - ((1 - R_0) * (1 - R_1) * ... * (1 - R_n))

const std = @import("std");

pub const BlockNode = union(enum) {
    series: Series,
    parallel: Parallel,
    module: f32,

    pub fn deinit(self: *BlockNode, alloc: std.mem.Allocator) void {
        switch (self.*) {
            .series => |*s| s.deinit(alloc),
            .parallel => |*p| p.deinit(alloc),
            .module => {},
        }
    }

    pub fn getReliability(self: *const BlockNode) f32 {
        return switch (self.*) {
            .series => |s| s.getReliability(),
            .parallel => |p| p.getReliability(),
            .module => |m| m,
        };
    }
};

pub const Series = struct {
    series: std.ArrayList(BlockNode) = .{},

    pub fn deinit(self: *Series, alloc: std.mem.Allocator) void {
        for (self.series.items) |*c| c.deinit(alloc);
        self.series.deinit(alloc);
    }

    pub fn add(self: *Series, alloc: std.mem.Allocator, block: BlockNode) !void {
        try self.series.append(alloc, block);
    }

    pub fn getReliability(self: *const Series) f32 {
        var reliability: f32 = 1;

        for (self.series.items) |module|
            reliability *= module.getReliability();

        return reliability;
    }
};

pub const Parallel = struct {
    parallel: std.ArrayList(BlockNode) = .{},

    pub fn deinit(self: *Parallel, alloc: std.mem.Allocator) void {
        for (self.parallel.items) |*c| c.deinit(alloc);
        self.parallel.deinit(alloc);
    }

    pub fn add(self: *Parallel, alloc: std.mem.Allocator, block: BlockNode) !void {
        try self.parallel.append(alloc, block);
    }

    pub fn getReliability(self: *const Parallel) f32 {
        var reliability: f32 = 1;

        for (self.parallel.items) |module|
            reliability *= (1 - module.getReliability());

        return 1 - reliability;
    }
};
