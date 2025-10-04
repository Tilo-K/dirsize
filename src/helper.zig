const std = @import("std");

pub fn formatAsFileSize(size: u64, allocator: std.mem.Allocator) ![]const u8 {
    if (size < 1024) {
        return std.fmt.allocPrint(allocator, "{d} bytes", .{size});
    } else if (size < 1024 * 1024) {
        return std.fmt.allocPrint(allocator, "{d} KiB", .{size / 1024});
    } else if (size < 1024 * 1024 * 1024) {
        return std.fmt.allocPrint(allocator, "{d} MiB", .{size / (1024 * 1024)});
    } else {
        return std.fmt.allocPrint(allocator, "{d} GiB", .{size / (1024 * 1024 * 1024)});
    }
}
