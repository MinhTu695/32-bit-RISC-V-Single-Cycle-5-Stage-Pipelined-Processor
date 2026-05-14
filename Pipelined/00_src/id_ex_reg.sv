//######################################################################
// MODULE: id_ex_reg (Structural Style - Corrected Signal Names)
//######################################################################
module id_ex_reg (
    input  logic        i_clk,
    input  logic        i_reset,  // Async Reset
    
    // --- PIPELINE FLOW CONTROL ---
    input  logic        i_flush,  // Flush từ Hazard Unit / Branch
    input  logic        i_stall,  // (Dự phòng)

    // --- DATA PATH INPUTS (Từ tầng ID) ---
    input  logic [31:0] PC_ID,
    input  logic [31:0] PCfour_ID,
    input  logic [31:0] instr_ID,      // Instruction
    input  logic [31:0] rs1_ID, 
    input  logic [31:0] rs2_ID, 
    input  logic [31:0] imm_ID,
    input  logic [4:0]  rd_addr_ID,    

    // --- CONTROL SIGNALS INPUTS ---
    // Nhóm EX (ALU, BRC)
    input  logic [3:0]  alu_op_ID,
    input  logic        i_br_un_ID,
    input  logic        i_insn_vld_ID, // [MỚI] Input tín hiệu Valid

    // Nhóm MEM (LSU)
    input  logic        mem_wren_ID, 
    input  logic        mem_rden_ID,
    input  logic [2:0]  mem_funct3_ID, 

    // Nhóm WB (RegFile)
    input  logic        rd_wren_ID,
    input  logic [1:0]  wb_sel_ID,

    // ================= OUTPUTS (Sang tầng EX) =================
    
    // --- DATA PATH OUTPUTS ---
    output logic [31:0] PC_EX,
    output logic [31:0] PCfour_EX,
    output logic [31:0] instr_EX,      
    output logic [31:0] rs1_EX, 
    output logic [31:0] rs2_EX, 
    output logic [31:0] imm_EX,
    output logic [4:0]  rd_addr_EX,
    output logic        o_insn_vld_EX, // [MỚI] Output tín hiệu Valid

    // --- CONTROL SIGNALS OUTPUTS ---
    output logic [3:0]  alu_op_EX,
    output logic        br_un_EX,
    output logic        mem_wren_EX, 
    output logic        mem_rden_EX,
    output logic [2:0]  mem_funct3_EX,
    output logic        rd_wren_EX,
    output logic [1:0]  wb_sel_EX
);

    // =================================================================
    // 1. THANH GHI PC, PC+4, RS1, RS2, IMM
    // =================================================================

    reg32 u_reg_pc (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PC_ID), 
        .d_out(PC_EX)
    );

    reg32 u_reg_pc_four (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PCfour_ID), 
        .d_out(PCfour_EX)
    );

    reg32 u_reg_rs1 (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(rs1_ID), 
        .d_out(rs1_EX)
    );

    reg32 u_reg_rs2 (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(rs2_ID), 
        .d_out(rs2_EX)
    );

    reg32 u_reg_imm (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(imm_ID), 
        .d_out(imm_EX)
    );

    // =================================================================
    // 2. THANH GHI INSTRUCTION (XỬ LÝ MUX CHO NOP)
    // =================================================================
    
    logic [31:0] instr_in_mux;
    logic        instr_stall_logic;

    // Logic MUX: Nếu Flush -> Chọn NOP (0x13). Nếu không -> Chọn instr_ID.
    assign instr_in_mux = (i_flush) ? 32'h0000_0013 : instr_ID;

    // Logic Stall:
    // Nếu Flush đang bật -> Stall = 0 (cho phép ghi NOP).
    // Nếu không Flush -> Stall = i_stall.
    assign instr_stall_logic = i_stall & (~i_flush);

    reg32 u_reg_instr (
        .i_clk   (i_clk), 
        .i_reset (i_reset),
        .flush   (1'b0),              // TẮT flush nội bộ
        .stall   (instr_stall_logic), // Dùng logic stall đặc biệt
        .d_in    (instr_in_mux),      // Data qua Mux
        .d_out   (instr_EX)
    );

    // =================================================================
    // 3. THANH GHI RD ADDRESS (5-bit)
    // =================================================================
    logic [31:0] rd_addr_extended_out;
    
    reg32 u_reg_rd_addr (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in({27'b0, rd_addr_ID}), // Mở rộng 5 bit -> 32 bit
        .d_out(rd_addr_extended_out)
    );
    assign rd_addr_EX = rd_addr_extended_out[4:0];

    // =================================================================
    // 4. THANH GHI CONTROL SIGNALS (GOM NHÓM)
    // =================================================================
    
    logic [31:0] ctrl_packet_in, ctrl_packet_out;
    
    // Đóng gói tín hiệu input (có hậu tố _ID)
    assign ctrl_packet_in = {
        18'b0,           // Padding (GIẢM 1 bit so với cũ)
        i_insn_vld_ID,   // [13] [MỚI] Tín hiệu Valid
        wb_sel_ID,       // [12:11]
        rd_wren_ID,      // [10]
        mem_funct3_ID,   // [9:7]
        mem_rden_ID,     // [6]
        mem_wren_ID,     // [5]
        i_br_un_ID,      // [4]
        alu_op_ID        // [3:0]
    };

    reg32 u_reg_control (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(ctrl_packet_in), 
        .d_out(ctrl_packet_out)
    );

    // Giải nén tín hiệu output (có hậu tố _EX)
    assign alu_op_EX     = ctrl_packet_out[3:0];
    assign br_un_EX      = ctrl_packet_out[4];
    assign mem_wren_EX   = ctrl_packet_out[5];
    assign mem_rden_EX   = ctrl_packet_out[6];
    assign mem_funct3_EX = ctrl_packet_out[9:7];
    assign rd_wren_EX    = ctrl_packet_out[10];
    assign wb_sel_EX     = ctrl_packet_out[12:11];
    assign o_insn_vld_EX = ctrl_packet_out[13]; // [MỚI]

endmodule