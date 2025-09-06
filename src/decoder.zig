const std = @import("std");

const instructions = @import("instructions.zig");
const Instruction = instructions.Instruction;
const Itype = instructions.Itype;
const Rtype = instructions.Rtype;
const Stype = instructions.Stype;
const Utype = instructions.Utype;
const Btype = instructions.Btype;
const Jtype = instructions.Jtype;

pub const DecoderError = error{
    DecoderError,
    Unsupported,
};

pub fn decode_instruction(inst: u32) !Instruction {
    const opcode = inst & 0x7f;
    switch (opcode & 0b11) {
        0b11 => switch (opcode >> 2) {
            0b00000 => {
                // LOAD
                const itype = Itype.init(inst);
                switch (itype.funct3 & 0b111) {
                    0b000 => return Instruction{ .lb = itype },
                    0b001 => return Instruction{ .lh = itype },
                    0b010 => return Instruction{ .lw = itype },
                    0b100 => return Instruction{ .lbu = itype },
                    0b101 => return Instruction{ .lhu = itype },
                    else => return error.DecoderError,
                }
            },
            0b00001 => {
                // LOAD-FP
                return error.Unsupported;
            },
            0b00011 => {
                // MISC-MEM
                return error.Unsupported;
            },
            0b00100 => {
                // OP-IMM
                const itype = Itype.init(inst);
                switch (itype.funct3) {
                    0b000 => return Instruction{ .addi = itype },
                    0b010 => return Instruction{ .slti = itype },
                    0b011 => return Instruction{ .sltiu = itype },
                    0b100 => return Instruction{ .xori = itype },
                    0b110 => return Instruction{ .ori = itype },
                    0b111 => return Instruction{ .andi = itype },
                    0b001 => return Instruction{ .slli = itype },
                    0b101 => switch ((itype.imm >> 10) & 0b1) {
                        0 => return Instruction{ .srli = itype },
                        1 => return Instruction{ .srai = itype },
                        else => unreachable,
                    },
                }
            },
            0b00101 => {
                // AUIPC
                const utype = Utype.init(inst);
                return Instruction{ .auipc = utype };
            },
            0b00110 => {
                // OP-IMM-32
                return error.Unsupported;
            },
            0b01000 => {
                // STORE
                const stype = Stype.init(inst);
                switch (stype.funct3 & 0b111) {
                    0b000 => return Instruction{ .sb = stype },
                    0b001 => return Instruction{ .sh = stype },
                    0b010 => return Instruction{ .sw = stype },
                    else => return error.DecoderError,
                }
            },
            0b01001 => {
                // STORE-FP
                return error.Unsupported;
            },
            0b01011 => {
                // AMO
                return error.Unsupported;
            },
            0b01100 => {
                // OP
                const rtype = Rtype.init(inst);
                switch (rtype.funct3) {
                    0b000 => switch ((rtype.funct7 >> 6) & 0b1) {
                        0 => return Instruction{ .add = rtype },
                        1 => return Instruction{ .sub = rtype },
                        else => unreachable,
                    },
                    0b001 => return Instruction{ .sll = rtype },
                    0b010 => return Instruction{ .slt = rtype },
                    0b011 => return Instruction{ .sltu = rtype },
                    0b100 => return Instruction{ .xor = rtype },
                    0b101 => switch ((rtype.funct7 >> 6) & 0b1) {
                        0 => return Instruction{ .srl = rtype },
                        1 => return Instruction{ .sra = rtype },
                        else => unreachable,
                    },
                    0b110 => return Instruction{ .or_ = rtype },
                    0b111 => return Instruction{ .and_ = rtype },
                }
            },
            0b01101 => {
                // LUI
                const utype = Utype.init(inst);
                return Instruction{ .lui = utype };
            },
            0b01110 => {
                // OP-32
                return error.Unsupported;
            },
            0b10000 => {
                // MADD
                return error.Unsupported;
            },
            0b10001 => {
                // MSUB
                return error.Unsupported;
            },
            0b10010 => {
                // NMSUB
                return error.Unsupported;
            },
            0b10011 => {
                // NMADD
                return error.Unsupported;
            },
            0b10100 => {
                // OP-FP
                return error.Unsupported;
            },
            0b11000 => {
                // BRANCH
                const btype = Btype.init(inst);
                switch (btype.funct3) {
                    0b000 => return Instruction{ .beq = btype },
                    0b001 => return Instruction{ .bne = btype },
                    0b100 => return Instruction{ .blt = btype },
                    0b101 => return Instruction{ .bge = btype },
                    0b110 => return Instruction{ .bltu = btype },
                    0b111 => return Instruction{ .bgeu = btype },
                    else => return error.Unsupported,
                }
            },
            0b11001 => {
                const itype = Itype.init(inst);
                switch (itype.funct3) {
                    0b000 => {
                        // JALR
                        return Instruction{ .jalr = itype };
                    },
                    else => return error.Unsupported,
                }
            },
            0b11011 => {
                // JAL
                const jtype = Jtype.init(inst);
                return Instruction{ .jal = jtype };
            },
            0b11100 => {
                // SYSTEM
                return error.Unsupported;
            },
            else => return error.Unsupported,
        },
        else => return error.Unsupported,
    }
}

test "decode andi ori xori" {
    try std.testing.expectEqual(decode_instruction(0x00457593), Instruction{ .andi = Itype.init(0x00457593) });
    try std.testing.expectEqual(decode_instruction(0x00256613), Instruction{ .ori = Itype.init(0x00256613) });
    try std.testing.expectEqual(decode_instruction(0x00a54693), Instruction{ .xori = Itype.init(0x00a54693) });
}
