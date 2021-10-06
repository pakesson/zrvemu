pub const Rtype = struct {
    rd: usize,
    funct3: u3,
    rs1: usize,
    rs2: usize,
    funct7: u7,

    pub fn init(inst: u32) Rtype {
        return Rtype{
            .rd = ((inst >> 7) & 0x1f),
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
            .funct7 = @intCast(u7, ((inst >> 25) & 0x7f)),
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
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
            .rs1 = ((inst >> 15) & 0x1f),
            .imm = @truncate(i32, @intCast(i64, @bitCast(i32, inst)) >> 20),
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
            .imm = @intCast(i32, (inst >> 7) & 0x1f) | (@bitCast(i32, inst & 0xfe000000) >> 20),
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
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
            .imm = @bitCast(i32, inst & 0xfffff000),
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
            .funct3 = @intCast(u3, ((inst >> 12) & 0x7)),
            .rs1 = ((inst >> 15) & 0x1f),
            .rs2 = ((inst >> 20) & 0x1f),
            .imm = @bitCast(i32, (((inst & 0x80000000) >> 19) |
                ((inst & 0x7e000000) >> 20) |
                ((inst & 0x00000f00) >> 7) |
                ((inst & 0x00000080) << 4))),
        };
    }
};

pub const Jtype = struct {
    rd: usize,
    imm: i32,

    pub fn init(inst: u32) Jtype {
        return Jtype{
            .rd = ((inst >> 7) & 0x1f),
            .imm = @bitCast(i32, (((inst & 0x80000000) >> 11) |
                ((inst & 0x7fe00000) >> 20) |
                ((inst & 0x00100000) >> 9) |
                (inst & 0x000ff000))),
        };
    }
};

pub const Instruction = union(enum) {
    add: Rtype,
    addi: Itype,
};
