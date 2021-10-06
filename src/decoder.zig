const instructions = @import("instructions.zig");
const Instruction = instructions.Instruction;
const Itype = instructions.Itype;
const Rtype = instructions.Rtype;

pub const Error = error{
    DecoderError,
};

pub fn decode_instruction(inst: u32) !Instruction {
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