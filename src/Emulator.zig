const std = @import("std");
const ArrayList = std.ArrayList;

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
        .regs = [_]u64{0}**32,
    };
}

pub fn deinit(self: *Self) void {

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
    return @intCast(u32, self.memory.items[self.pc])
        | @intCast(u32, self.memory.items[self.pc + 1]) << 8
        | @intCast(u32, self.memory.items[self.pc + 2]) << 16
        | @intCast(u32, self.memory.items[self.pc + 3]) << 24;
}

pub fn execute_instruction(self: *Self, inst: Instruction) void {
    switch (inst) {
        .add => |*rtype| {
            self.setreg(
                rtype.rd,
                self.getreg(rtype.rs1) +% self.getreg(rtype.rs2)
            );
        },
        .addi => |*itype| {
            self.setreg(
                itype.rd,
                self.getreg(itype.rs1) +% @bitCast(u64, @intCast(i64, itype.imm))
            );
        },
    }
}

pub fn print_state(self: *const Self) void {
    for (self.regs) |reg, index| {
        std.log.info("x{} = {x}", .{index, reg});
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