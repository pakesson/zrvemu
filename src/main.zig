const std = @import("std");
const ArrayList = std.ArrayList;
const zrvemu = @import("zrvemu");

pub fn main() anyerror!void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpalloc.deinit() == .ok);
    const allocator = gpalloc.allocator();

    var memory: ArrayList(u8) = .empty;
    defer memory.deinit(allocator);

    const file_path = "examples/fib.bin"; // Update this path

    const file_contents = try std.fs.cwd().readFileAlloc(allocator, file_path, std.math.maxInt(usize));
    defer allocator.free(file_contents);

    try memory.appendSlice(allocator, file_contents);

    try memory.ensureTotalCapacity(allocator, 100 * 1024 * 1024);
    memory.expandToCapacity();

    var emulator = zrvemu.Emulator.init(memory);

    // Set the stack pointer (sp) to the end of memory
    // TODO: Handle this in Emulator instead
    emulator.regs[2] = @as(u32, @truncate(memory.items.len - 1));

    emulator.run();

    std.log.info("Done. State:", .{});
    emulator.print_state();
}
