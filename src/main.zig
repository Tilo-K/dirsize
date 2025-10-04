const std = @import("std");
const helper = @import("helper.zig");
const scanner = @import("scanner.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);

    _ = args.skip();

    const file_path = args.next() orelse ".";

    std.debug.print("Reading directory: {s}\n", .{file_path});

    const startDir = std.fs.cwd().openDir(file_path, .{ .iterate = true }) catch |err| {
        std.debug.print("Error: {s}\n", .{@errorName(err)});
        return;
    };

    var dir_stack = std.ArrayList(std.fs.Dir).initCapacity(allocator, 100) catch |err| {
        std.debug.print("Out of memory :(\n{s}\n", .{@errorName(err)});
        return;
    };

    dir_stack.append(allocator, startDir) catch unreachable;

    var file_size_sum: u64 = 0;
    const time_start = std.time.milliTimestamp();

    while (dir_stack.items.len > 0) {
        var dir = dir_stack.pop().?;
        defer dir.close();

        file_size_sum += try scanner.scanDir(dir, &dir_stack, allocator);
    }

    const time_end = std.time.milliTimestamp();

    const formatted_size = try helper.formatAsFileSize(file_size_sum, allocator);
    std.debug.print("Total size: {s}\n", .{formatted_size});
    std.debug.print("Time elapsed: {d} ms\n", .{time_end - time_start});
}
