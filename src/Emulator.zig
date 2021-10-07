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

pub fn deinit(self: *Self) void {}

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
    return @intCast(u32, self.memory.items[self.pc]) |
        @intCast(u32, self.memory.items[self.pc + 1]) << 8 |
        @intCast(u32, self.memory.items[self.pc + 2]) << 16 |
        @intCast(u32, self.memory.items[self.pc + 3]) << 24;
}

pub fn execute_instruction(self: *Self, inst: Instruction) void {
    switch (inst) {
        .add => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) +% self.getreg(val.rs2));
        },
        .addi => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm)));
        },
        .and_ => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) & self.getreg(val.rs2));
        },
        .andi => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) & @bitCast(u64, @intCast(i64, val.imm)));
        },
        .auipc => |*val| {
            self.setreg(val.rd, (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm)));
        },
        .beq => |*val| {
            if (self.getreg(val.rs1) == self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .bge => |*val| {
            if (@bitCast(i64, self.getreg(val.rs1)) >= @bitCast(i64, self.getreg(val.rs2))) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .bgeu => |*val| {
            if (self.getreg(val.rs1) >= self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .blt => |*val| {
            if (@bitCast(i64, self.getreg(val.rs1)) < @bitCast(i64, self.getreg(val.rs2))) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .bltu => |*val| {
            if (self.getreg(val.rs1) < self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .bne => |*val| {
            if (self.getreg(val.rs1) != self.getreg(val.rs2)) {
                // PC has already been increased
                self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
            }
        },
        .jal => |*val| {
            // TODO: instruction-address-misaligned exception if address is not aligned
            // PC has already been increased
            self.setreg(val.rd, self.pc);
            self.pc = (self.pc -% 4) +% @bitCast(u64, @intCast(i64, val.imm));
        },
        .jalr => |*val| {
            // TODO: instruction-address-misaligned exception if address is not aligned
            // PC has already been increased
            self.setreg(val.rd, self.pc);
            self.pc = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
        },
        .lb => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = @bitCast(u64, @intCast(i64, @bitCast(i8, self.memory.items[address])));
            self.setreg(val.rd, value);
        },
        .lbu => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = @intCast(u64, self.memory.items[address]);
            self.setreg(val.rd, value);
        },
        .lh => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = @bitCast(u64, @intCast(i64, @bitCast(i16, @intCast(u16, self.memory.items[address]) |
                (@intCast(u16, self.memory.items[address + 1]) << 8))));
            self.setreg(val.rd, value);
        },
        .lhu => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = @intCast(u64, self.memory.items[address]) |
                (@intCast(u64, self.memory.items[address + 1]) << 8);
            self.setreg(val.rd, value);
        },
        .lui => |*val| {
            self.setreg(val.rd, @bitCast(u64, @intCast(i64, val.imm)));
        },
        .lw => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = @intCast(u64, self.memory.items[address]) |
                (@intCast(u64, self.memory.items[address + 1]) << 8) |
                (@intCast(u64, self.memory.items[address + 2]) << 16) |
                (@intCast(u64, self.memory.items[address + 3]) << 24);
            self.setreg(val.rd, value);
        },
        .or_ => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) | self.getreg(val.rs2));
        },
        .ori => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) | @bitCast(u64, @intCast(i64, val.imm)));
        },
        .sb => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            self.memory.items[address] = @truncate(u8, self.getreg(val.rs2));
        },
        .sh => |*val| {
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = self.getreg(val.rs2);
            self.memory.items[address] = @truncate(u8, value);
            self.memory.items[address + 1] = @truncate(u8, value >> 8);
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
            self.setreg(val.rd, @boolToInt(@bitCast(i64, self.getreg(val.rs1)) < @bitCast(i64, self.getreg(val.rs2))));
        },
        .slti => |*val| {
            self.setreg(val.rd, @boolToInt(@bitCast(i64, self.getreg(val.rs1)) < @intCast(i64, val.imm)));
        },
        .sltiu => |*val| {
            self.setreg(val.rd, @boolToInt(self.getreg(val.rs1) < @bitCast(u64, @intCast(i64, val.imm))));
        },
        .sltu => |*val| {
            self.setreg(val.rd, @boolToInt(self.getreg(val.rs1) < self.getreg(val.rs2)));
        },
        .sra => |*val| {
            const shamt = self.getreg(val.rs2) & 0b11111;
            self.setreg(val.rd, @bitCast(u64, math.shr(i64, @bitCast(i64, self.getreg(val.rs1)), shamt)));
        },
        .srai => |*val| {
            const shamt = val.imm & 0b11111;
            self.setreg(val.rd, @bitCast(u64, math.shr(i64, @bitCast(i64, self.getreg(val.rs1)), shamt)));
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
            const address = self.getreg(val.rs1) +% @bitCast(u64, @intCast(i64, val.imm));
            const value = self.getreg(val.rs2);
            self.memory.items[address] = @truncate(u8, value);
            self.memory.items[address + 1] = @truncate(u8, value >> 8);
            self.memory.items[address + 2] = @truncate(u8, value >> 16);
            self.memory.items[address + 3] = @truncate(u8, value >> 24);
        },
        .xor => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) ^ self.getreg(val.rs2));
        },
        .xori => |*val| {
            self.setreg(val.rd, self.getreg(val.rs1) ^ @bitCast(u64, @intCast(i64, val.imm)));
        },
    }
}

pub fn print_state(self: *const Self) void {
    for (self.regs) |reg, index| {
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
            else => return,
        };
        self.pc += 4;
        self.execute_instruction(decoded_inst);
    }
}
