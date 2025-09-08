const std = @import("std");
const ArrayList = std.ArrayList;
const math = std.math;

const Instruction = @import("instructions.zig").Instruction;
const decode_instruction = @import("decoder.zig").decode_instruction;

const Self = @This();

memory: ArrayList(u8),
pc: u64,
regs: [32]u64,

pub fn init(memory: ArrayList(u8)) Self {
    return Self{
        .memory = memory,
        .pc = 0,
        .regs = [_]u64{0} ** 32,
    };
}

pub fn getreg(self: *const Self, reg: usize) u64 {
    if (reg == 0) {
        return 0;
    } else {
        return self.regs[reg];
    }
}

pub fn setreg(self: *Self, reg: usize, val: u64) void {
    if (reg != 0) {
        self.regs[reg] = val;
    }
}

pub fn fetch_instruction(self: *const Self) u32 {
    return std.mem.readInt(u32, self.memory.items[self.pc..][0..4], .little);
}

pub fn execute_instruction(self: *Self, inst: Instruction) void {
    switch (inst) {
        .add => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) +% self.getreg(val.rs2));
        },
        .addi => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm))));
        },
        .and_ => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) & self.getreg(val.rs2));
        },
        .andi => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) & @as(u64, @bitCast(@as(i64, val.imm))));
        },
        .auipc => |*val| {
            self.setreg(val.rd, (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm))));
        },
        .beq => |*val| {
            if (self.getreg(val.rs1) == self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .bge => |*val| {
            if (@as(i64, @bitCast(self.getreg(val.rs1))) >= @as(i64, @bitCast(self.getreg(val.rs2)))) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .bgeu => |*val| {
            if (self.getreg(val.rs1) >= self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .blt => |*val| {
            if (@as(i64, @bitCast(self.getreg(val.rs1))) < @as(i64, @bitCast(self.getreg(val.rs2)))) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .bltu => |*val| {
            if (self.getreg(val.rs1) < self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .bne => |*val| {
            if (self.getreg(val.rs1) != self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
            }
        },
        .jal => |*val| {
            // TODO: instruction-address-misaligned exception if address is not aligned
            // PC has already been increased
            self.setreg(val.rd, self.pc);
            self.pc = (self.pc -% 4) +% @as(u64, @bitCast(@as(i64, val.imm)));
        },
        .jalr => |*val| {
            // TODO: instruction-address-misaligned exception if address is not aligned
            // PC has already been increased
            self.setreg(val.rd, self.pc);
            self.pc = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
        },
        .lb => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value: u64 = @bitCast(@as(i64, @as(i8, @bitCast(self.memory.items[address]))));
            self.setreg(val.rd, value);
        },
        .lbu => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value: u64 = @intCast(self.memory.items[address]);
            self.setreg(val.rd, value);
        },
        .lh => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value: u64 = @bitCast(@as(i64, std.mem.readInt(i16, self.memory.items[address..][0..2], .little)));
            self.setreg(val.rd, value);
        },
        .lhu => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value = @as(u64, std.mem.readInt(u16, self.memory.items[address..][0..2], .little));
            self.setreg(val.rd, value);
        },
        .lui => |*val| {
            self.setreg(val.rd, @as(u64, @bitCast(@as(i64, val.imm))));
        },
        .lw => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value = @as(u64, std.mem.readInt(u32, self.memory.items[address..][0..4], .little));
            self.setreg(val.rd, value);
        },
        .or_ => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) | self.getreg(val.rs2));
        },
        .ori => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) | @as(u64, @bitCast(@as(i64, val.imm))));
        },
        .sb => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            self.memory.items[address] = @as(u8, @truncate(self.getreg(val.rs2)));
        },
        .sh => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value = @as(u16, @truncate(self.getreg(val.rs2)));
            std.mem.writeInt(u16, self.memory.items[address..][0..2], value, .little);
        },
        .sll => |*val| {
            const shamt = self.getreg(val.rs2) & 0b11111;
            self.setreg(val.rd, math.shl(u64, self.getreg(val.rs1), shamt));
        },
        .slli => |*val| {
            const shamt = val.imm & 0b11111;
            self.setreg(val.rd, math.shl(u64, self.getreg(val.rs1), shamt));
        },
        .slt => |*val| {
            self.setreg(val.rd, @intFromBool(@as(i64, @bitCast(self.getreg(val.rs1))) < @as(i64, @bitCast(self.getreg(val.rs2)))));
        },
        .slti => |*val| {
            self.setreg(val.rd, @intFromBool(@as(i64, @bitCast(self.getreg(val.rs1))) < @as(i64, val.imm)));
        },
        .sltiu => |*val| {
            self.setreg(val.rd, @intFromBool(self.getreg(val.rs1) < @as(u64, @bitCast(@as(i64, val.imm)))));
        },
        .sltu => |*val| {
            self.setreg(val.rd, @intFromBool(self.getreg(val.rs1) < self.getreg(val.rs2)));
        },
        .sra => |*val| {
            const shamt = self.getreg(val.rs2) & 0b11111;
            self.setreg(val.rd, @as(u64, @bitCast(math.shr(i64, @as(i64, @bitCast(self.getreg(val.rs1))), shamt))));
        },
        .srai => |*val| {
            const shamt = val.imm & 0b11111;
            self.setreg(val.rd, @as(u64, @bitCast(math.shr(i64, @as(i64, @bitCast(self.getreg(val.rs1))), shamt))));
        },
        .srl => |*val| {
            const shamt = self.getreg(val.rs2) & 0b11111;
            self.setreg(val.rd, math.shr(u64, self.getreg(val.rs1), shamt));
        },
        .srli => |*val| {
            const shamt = val.imm & 0b11111;
            self.setreg(val.rd, math.shr(u64, self.getreg(val.rs1), shamt));
        },
        .sub => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) -% self.getreg(val.rs2));
        },
        .sw => |*val| {
            const address = self.getreg(val.rs1) +% @as(u64, @bitCast(@as(i64, val.imm)));
            const value = self.getreg(val.rs2);
            self.memory.items[address] = @as(u8, @truncate(value));
            self.memory.items[address + 1] = @as(u8, @truncate(value >> 8));
            self.memory.items[address + 2] = @as(u8, @truncate(value >> 16));
            self.memory.items[address + 3] = @as(u8, @truncate(value >> 24));
        },
        .xor => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) ^ self.getreg(val.rs2));
        },
        .xori => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) ^ @as(u64, @bitCast(@as(i64, val.imm))));
        },
    }
}

pub fn print_state(self: *const Self) void {
    for (self.regs, 0..) |reg, index| {
        std.log.info("x{} = {x}", .{ index, reg });
    }
    std.log.info("pc = {}", .{self.pc});
}

pub fn run(self: *Self) void {
    while (true) {
        if (self.pc >= self.memory.items.len) break;

        const inst = self.fetch_instruction();
        const decoded_inst = decode_instruction(inst) catch |err| switch (err) {
            error.DecoderError => {
                std.log.err("Could not decode instruction", .{});
                return;
            },
            error.Unsupported => {
                std.log.err("Unsupported instruction", .{});
                return;
            },
        };
        self.pc += 4;
        self.execute_instruction(decoded_inst);
    }
}

test "execute add addi" {
    var memory: ArrayList(u8) = .empty;
    defer memory.deinit(std.testing.allocator);
    try memory.appendSlice(std.testing.allocator, &[_]u8{
        0x13, 0x05, 0x60, 0x00, // addi a0,x0,6 (li a0,6)
        0x93, 0x05, 0x40, 0x00, // addi a1,x0,4 (li a1,4)
        0x33, 0x05, 0xb5, 0x00, // add a0,a0,a1
    });

    var emulator = Self.init(memory);
    emulator.run();

    try std.testing.expectEqual(emulator.getreg(10), 0x0a);
}

test "execute auipc lw" {
    var memory: ArrayList(u8) = .empty;
    defer memory.deinit(std.testing.allocator);
    try memory.appendSlice(std.testing.allocator, &[_]u8{
        0x17, 0x05, 0x00, 0x00, // auipc a0,0x0
        0x03, 0x25, 0x05, 0x00, // lw    a0,0(a0)
    });

    var emulator = Self.init(memory);
    emulator.run();

    try std.testing.expectEqual(emulator.getreg(10), 0x00000517);
}

test "execute andi li ori xori" {
    var memory: ArrayList(u8) = .empty;
    defer memory.deinit(std.testing.allocator);
    try memory.appendSlice(std.testing.allocator, &[_]u8{
        0x13, 0x05, 0x50, 0x00, // li   a0,5
        0x93, 0x75, 0x45, 0x00, // andi a1,a0,4
        0x13, 0x66, 0x25, 0x00, // ori  a2,a0,2
        0x93, 0x46, 0xa5, 0x00, // xori a3,a0,10
    });

    var emulator = Self.init(memory);
    emulator.run();

    try std.testing.expectEqual(emulator.getreg(10), 0x00000005);
    try std.testing.expectEqual(emulator.getreg(11), 0x00000004);
    try std.testing.expectEqual(emulator.getreg(12), 0x00000007);
    try std.testing.expectEqual(emulator.getreg(13), 0x0000000f);
}
