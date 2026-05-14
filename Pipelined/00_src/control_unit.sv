module control_unit (
    // --- Input ---
    // Nhận Instruction đang ở tầng Decode (ID)
    input  logic [31:0] inst_ID,

    // =======================================================
    // NHÓM 1: TÍN HIỆU CHO TẦNG ID (Dùng ngay tại chỗ)
    // =======================================================
    output logic [2:0] o_imm_sel,    // Điều khiển Imm Gen

    // =======================================================
    // NHÓM 2: TÍN HIỆU CHO TẦNG EX (Lưu vào ID/EX Reg)
    // =======================================================
    // Điều khiển ALU (Module cũ)
    output logic [3:0] o_alu_op,     
    // Dựa trên code BRC của bạn: 1 = Signed, 0 = Unsigned
    output logic       o_br_un,      
    output logic        o_insn_vld,// nối tầng
    // =======================================================
    // NHÓM 3: TÍN HIỆU CHO TẦNG MEM (Lưu vào ID/EX -> EX/MEM Reg)
    // =======================================================
    // Điều khiển Data Memory / LSU (Module cũ)
    output logic       o_mem_wren,   // Write Enable (Store)
    output logic       o_mem_read,   // Read Enable (Load - Dùng cho Hazard Unit)
    output logic [2:0] o_mem_funct3, // Data size (Byte/Half/Word)

    // =======================================================
    // NHÓM 4: TÍN HIỆU CHO TẦNG WB (Lưu vào ID/EX -> ... -> MEM/WB Reg)
    // =======================================================
    // Điều khiển Register File (Module cũ)
    output logic       o_rd_wren,    // Reg Write Enable
    output logic [1:0] o_wb_sel      // Select Data to Reg
);

    //============================================================
    // 1. GIẢI MÃ OPCODE & FUNCT
    //============================================================
    logic [4:0] op;
    logic [2:0] funct3;
    logic       funct7_5;

    assign op       = inst_ID[6:2];   // [cite: 23]
    assign funct3   = inst_ID[14:12]; // [cite: 24]
    assign funct7_5 = inst_ID[30];    // [cite: 26]

    // Phân loại Opcode (Dựa trên logic cũ [cite: 33-41])
    wire op_rtype  = (~op[4]) & ( op[3]) & ( op[2]) & (~op[1]) & (~op[0]); 
    wire op_itype  = (~op[4]) & (~op[3]) & ( op[2]) & (~op[1]) & (~op[0]); 
    wire op_load   = (~op[4]) & (~op[3]) & (~op[2]) & (~op[1]) & (~op[0]); 
    wire op_store  = (~op[4]) & ( op[3]) & (~op[2]) & (~op[1]) & (~op[0]); 
    wire op_branch = ( op[4]) & ( op[3]) & (~op[2]) & (~op[1]) & (~op[0]); 
    wire op_jal    = ( op[4]) & ( op[3]) & (~op[2]) & ( op[1]) & ( op[0]); 
    wire op_jalr   = ( op[4]) & ( op[3]) & (~op[2]) & (~op[1]) & ( op[0]); 
    wire op_lui    = (~op[4]) & ( op[3]) & ( op[2]) & (~op[1]) & ( op[0]); 
    wire op_auipc  = (~op[4]) & (~op[3]) & ( op[2]) & (~op[1]) & ( op[0]); 

    // Giải mã Funct3 (Dựa trên logic cũ [cite: 42-46])
    wire f3_000 = (funct3 == 3'b000);
    wire f3_001 = (funct3 == 3'b001);
    wire f3_010 = (funct3 == 3'b010);
    wire f3_011 = (funct3 == 3'b011);
    wire f3_100 = (funct3 == 3'b100);
    wire f3_101 = (funct3 == 3'b101);
    wire f3_110 = (funct3 == 3'b110);
    wire f3_111 = (funct3 == 3'b111);

    //============================================================
    // 2. TẠO TÍN HIỆU CONTROL
    //============================================================

    // --- A. TÍN HIỆU ID (ImmGen) ---
    assign o_imm_sel[0] = op_itype | op_load | op_jalr | op_branch | op_jal;
    assign o_imm_sel[1] = op_store | op_branch;
    assign o_imm_sel[2] = op_lui | op_auipc | op_jal;

    // --- B. TÍN HIỆU EX (ALU & BRC) ---
    
    // o_alu_op
    wire alu_valid = op_rtype | op_itype;
    wire is_sub    = op_rtype & f3_000 & funct7_5;
    wire is_sra    = alu_valid & f3_101 & funct7_5;

    assign o_alu_op[0] = is_sub | is_sra | op_lui;
    assign o_alu_op[1] = (alu_valid & (f3_001 | f3_011 | f3_101 | f3_111)) | op_lui;
    assign o_alu_op[2] = (alu_valid & (f3_010 | f3_011 | f3_110 | f3_111)) | op_lui;
    assign o_alu_op[3] = (alu_valid & (f3_100 | f3_101 | f3_110 | f3_111)) | op_lui;

    assign o_insn_vld = op_rtype | op_itype | op_load | op_store | 
                        op_branch | op_jal | op_jalr | op_lui | op_auipc;


    //1 = Có dấu (BLT, BGE).
    assign o_br_un = op_branch & (f3_100 | f3_101); 

    // --- C. TÍN HIỆU MEM (LSU) ---
    assign o_mem_wren   = op_store; // [cite: 69]
    assign o_mem_read   = op_load;  // Quan trọng cho Hazard Unit
    assign o_mem_funct3 = funct3;   // [cite: 70]

    // --- D. TÍN HIỆU WB (RegFile) ---
    // o_rd_wren: [cite: 66]
    assign o_rd_wren = op_rtype | op_itype | op_load | op_jal | op_jalr | op_auipc | op_lui;
    
    // o_wb_sel: [cite: 68]
    assign o_wb_sel[0] = op_load;
    assign o_wb_sel[1] = op_jal | op_jalr;

endmodule