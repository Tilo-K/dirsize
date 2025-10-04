const std = @import("std");
const helper = @import("helper.zig");
const scanner = @import("scanner.zig");

const SharedData = struct {
    stack_mutex: std.Thread.Mutex = .{},
    file_size_sum: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    dir_stack: std.ArrayList(std.fs.Dir) = .{},
    allocator: std.mem.Allocator = undefined,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);

    _ = args.skip();

    const file_path = args.next() orelse ".";

    std.debug.print("Reading directory: {s}\n", .{file_path});

    var startDir = std.fs.cwd().openDir(file_path, .{ .iterate = true }) catch |err| {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    const dir_stack = std.ArrayList(std.fs.Dir).initCapacity(allocator, 100) catch |err| {
        std.debug.print("Out of memory :(\n{s}\n", .{@errorName(err)});
        return;
    };

    var sharedData = SharedData{};
    sharedData.dir_stack = dir_stack;
    sharedData.allocator = allocator;

    const time_start = std.time.milliTimestamp();
    const file_sizes = try scanner.scanDir(startDir, &sharedData.dir_stack, allocator, &sharedData.stack_mutex);
    _ = sharedData.file_size_sum.fetchAdd(file_sizes, .monotonic);

    defer startDir.close();
    const cpus = try std.Thread.getCpuCount();
    std.debug.print("CPUs: {d}\n", .{cpus});

    const threads = allocator.alloc(std.Thread, cpus) catch |err| {
        std.debug.print("Out of memory :(\n{s}\n", .{@errorName(err)});
        return;
    };

    for (0..cpus) |i| {
        threads[i] = try std.Thread.spawn(.{}, worker, .{&sharedData});
    }

    for (0..cpus) |i| {
        _ = threads[i].join();
    }

    const thread = try std.Thread.spawn(.{}, worker, .{&sharedData});
    _ = thread.join();

    const time_end = std.time.milliTimestamp();

    const formatted_size = try helper.formatAsFileSize(sharedData.file_size_sum.raw, allocator);
    std.debug.print("Total size: {s}\n", .{formatted_size});
    std.debug.print("Time elapsed: {d} ms\n", .{time_end - time_start});
}

fn worker(sharedData: *SharedData) void {
    while (sharedData.dir_stack.items.len > 0) {
        sharedData.stack_mutex.lock();
        var dir = sharedData.dir_stack.pop() orelse {
            continue;
        };
        sharedData.stack_mutex.unlock();

        defer dir.close();

        const file_sizes = try scanner.scanDir(dir, &sharedData.dir_stack, sharedData.allocator, &sharedData.stack_mutex);
        _ = sharedData.file_size_sum.fetchAdd(file_sizes, .monotonic);
    }
}
