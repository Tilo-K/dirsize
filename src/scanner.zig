const std = @import("std");

pub fn scanDir(dir: std.fs.Dir, dir_stack: *std.ArrayList(std.fs.Dir), allocator: std.mem.Allocator, mutex: *std.Thread.Mutex) !u64 {
    var iter = dir.iterate();
    var file_size_sum: u64 = 0;

    while (true) {
        const next = iter.next() catch {
            continue;
        };

        if (next) |entry| {
            if (entry.kind == .directory) {
                var new_dir = dir.openDir(entry.name, .{ .iterate = true }) catch |err| {
                    if (err == error.AccessDenied) continue;
                    std.debug.print("Failed to open dir: {s}\n", .{@errorName(err)});
                    continue;
                };

                mutex.lock();
                defer mutex.unlock();
                dir_stack.append(allocator, new_dir) catch |err| {
                    std.debug.print("Out of memory: {s}\n", .{@errorName(err)});
                    new_dir.close();
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
