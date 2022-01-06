const std = @import("std");
const ArrayList = std.ArrayList;

const Emulator = @import("Emulator.zig");

pub fn main() anyerror!void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpalloc.deinit());
    const allocator = gpalloc.allocator();

    var memory = ArrayList(u8).init(allocator);
    defer memory.deinit();
    try memory.appendSlice(&[12]u8{
        0x13, 0x05, 0x60, 0x00, // addi a0,x0,6 (li a0,6)
        0x93, 0x05, 0x40, 0x00, // addi a1,x0,4 (li a1,4)
        0x33, 0x05, 0xb5, 0x00, // add a0,a0,a1
    });

    var emulator = Emulator.init(memory);
    emulator.run();

    std.log.info("Done. State:", .{});
    emulator.print_state();
}
