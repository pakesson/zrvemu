const std = @import("std");
const ArrayList = std.ArrayList;

const Self = @This();

const Rtype = struct {
    rd: usize,
    funct3: u3,
    rs1: usize,
    rs2: usize,
    funct7: u7,

    pub fn init(inst: u32) Rtype {
        return Rtype {
            .rd = ((inst >> 7) & 0x1f),
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
            .funct7 = @intCast(u7, ((inst >> 25) & 0x7f)),
        };
    }
};

const Itype = struct {
    rd: usize,
    funct3: u3,
    rs1: usize,
    imm: i32,

    pub fn init(inst: u32) Itype {
        return Itype {
            .rd = ((inst >> 7) & 0x1f),
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
            .rs1 = ((inst >> 15) & 0x1f),
            .imm = @truncate(i32, @intCast(i64, @bitCast(i32, inst)) >> 20),
        };
    }
};

const Instruction = union(enum) {
    add: Rtype,
    addi: Itype,
};

pub const Error = error{
    DecoderError,
};

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

pub fn decode_instruction(self: *const Self, inst: u32) !Instruction {
    var opcode = inst & 0x7f;
    switch (opcode & 0b11) {
        0b11 => switch (opcode >> 2) {
            0b00100 => {
                // OP-IMM
                const itype = Itype.init(inst);
                switch (itype.funct3) {
                    // ADDI
                    0b000 => return Instruction{.addi = itype},
                    else => return Error.DecoderError,
                }
            },
            0b01100 => {
                // OP
                const rtype = Rtype.init(inst);
                switch (rtype.funct3) {
                    0b000 => switch ((rtype.funct7 >> 6) & 0b1) {
                        // ADD
                        0 => return Instruction{.add = rtype},
                        // SUB
                        1 => return Error.DecoderError,
                        else => unreachable,
                    },
                    else => return Error.DecoderError,
                }
            },
            else => return Error.DecoderError,
        },
        else => return Error.DecoderError,
    }
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
        const decoded_inst = self.decode_instruction(inst) catch |err| switch (err) {
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