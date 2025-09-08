const std = @import("std");

pub const Rtype = struct {
    rd: usize,
    funct3: u3,
    rs1: usize,
    rs2: usize,
    funct7: u7,

    pub fn init(inst: u32) Rtype {
        return Rtype{
            .rd = ((inst >> 7) & 0x1f),
            .funct3 = @as(u3, @intCast(((inst >> 12) & 0x7))),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
            .funct7 = @as(u7, @intCast(((inst >> 25) & 0x7f))),
        };
    }
};

pub const Itype = struct {
    rd: usize,
    funct3: u3,
    rs1: usize,
    imm: i32,

    pub fn init(inst: u32) Itype {
        return Itype{
            .rd = ((inst >> 7) & 0x1f),
            .funct3 = @as(u3, @intCast(((inst >> 12) & 0x7))),
            .rs1 = ((inst >> 15) & 0x1f),
            .imm = @truncate(@as(i64, @as(i32, @bitCast(inst))) >> 20),
        };
    }
};

pub const Stype = struct {
    imm: i32,
    funct3: u3,
    rs1: usize,
    rs2: usize,

    pub fn init(inst: u32) Stype {
        return Stype{
            .imm = @as(i32, @intCast((inst >> 7) & 0x1f)) | (@as(i32, @bitCast(inst & 0xfe000000)) >> 20),
            .funct3 = @as(u3, @intCast(((inst >> 12) & 0x7))),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
        };
    }
};

pub const Utype = struct {
    rd: usize,
    imm: i32,

    pub fn init(inst: u32) Utype {
        return Utype{
            .rd = ((inst >> 7) & 0x1f),
            .imm = @as(i32, @bitCast(inst & 0xfffff000)),
        };
    }
};

pub const Btype = struct {
    funct3: u3,
    rs1: usize,
    rs2: usize,
    imm: i32,

    pub fn init(inst: u32) Btype {
        return Btype{
            .funct3 = @as(u3, @intCast(((inst >> 12) & 0x7))),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
            .imm = @as(i32, @bitCast((((inst & 0x80000000) >> 19) |
                ((inst & 0x7e000000) >> 20) |
                ((inst & 0x00000f00) >> 7) |
                ((inst & 0x00000080) << 4)))),
        };
    }
};

pub const Jtype = struct {
    rd: usize,
    imm: i32,

    pub fn init(inst: u32) Jtype {
        return Jtype{
            .rd = ((inst >> 7) & 0x1f),
            .imm = @as(i32, @bitCast((((inst & 0x80000000) >> 11) |
                ((inst & 0x7fe00000) >> 20) |
                ((inst & 0x00100000) >> 9) |
                (inst & 0x000ff000)))),
        };
    }
};

pub const Instruction = union(enum) {
    add: Rtype,
    addi: Itype,
    and_: Rtype, // and is a keyword
    andi: Itype,
    auipc: Utype,
    beq: Btype,
    bne: Btype,
    blt: Btype,
    bge: Btype,
    bltu: Btype,
    bgeu: Btype,
    jal: Jtype,
    jalr: Itype,
    lui: Utype,
    lb: Itype,
    lbu: Itype,
    lh: Itype,
    lhu: Itype,
    lw: Itype,
    or_: Rtype, // or is a keyword
    ori: Itype,
    sb: Stype,
    sh: Stype,
    sll: Rtype,
    slli: Itype,
    slt: Rtype,
    slti: Itype,
    sltiu: Itype,
    sltu: Rtype,
    srl: Rtype,
    srli: Itype,
    sra: Rtype,
    srai: Itype,
    sw: Stype,
    sub: Rtype,
    xor: Rtype,
    xori: Itype,
};

test "decode itype" {
    const inst = Itype.init(0x80152583); // lw  a1,-2047(a0)
    try std.testing.expectEqual(inst.rs1, 10); // base
    try std.testing.expectEqual(inst.rd, 11); // dst
    try std.testing.expectEqual(inst.funct3, 0b010); // width
    try std.testing.expectEqual(inst.imm, -2047); // offset
}

test "decode stype" {
    {
        const inst = Stype.init(0x80b520a3); // sw  a1,-2047(a0)
        try std.testing.expectEqual(inst.rs1, 10); // base
        try std.testing.expectEqual(inst.rs2, 11); // src
        try std.testing.expectEqual(inst.funct3, 0b010); // width
        try std.testing.expectEqual(inst.imm, -2047); // offset
    }

    {
        const inst = Stype.init(0x7eb52fa3); // sw  a1,2047(a0)
        try std.testing.expectEqual(inst.rs1, 10); // base
        try std.testing.expectEqual(inst.rs2, 11); // src
        try std.testing.expectEqual(inst.funct3, 0b010); // width
        try std.testing.expectEqual(inst.imm, 2047); // offset
    }
}
