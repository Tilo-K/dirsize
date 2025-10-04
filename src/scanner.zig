const std = @import("std");

pub fn scanDir(dir: std.fs.Dir, dir_stack: *std.ArrayList(std.fs.Dir), allocator: std.mem.Allocator) !u64 {
    var iter = dir.iterate();
    var file_size_sum: u64 = 0;

    while (true) {
        const next = iter.next() catch {
            continue;
        };

        if (next) |entry| {
            if (entry.kind == .directory) {
                dir_stack.append(allocator, dir.openDir(entry.name, .{ .iterate = true }) catch unreachable) catch |err| {
                    std.debug.print("Out of memory :(\n{s}\n", .{@errorName(err)});
                    continue;
                };
            } else if (entry.kind == .file) {
                const stat = dir.statFile(entry.name) catch |err| {
                    std.debug.print("Error: {s}\n", .{@errorName(err)});
                    continue;
                };

                file_size_sum += stat.size;
            }
        } else break;
    }

    return file_size_sum;
}
