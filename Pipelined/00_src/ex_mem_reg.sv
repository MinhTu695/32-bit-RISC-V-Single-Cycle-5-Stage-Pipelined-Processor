//######################################################################
// MODULE: ex_mem_reg (Structural Style - Corrected Signal Names)
//######################################################################
module ex_mem_reg (
    input  logic        i_clk,
    input  logic        i_reset,  // Async Reset
    
    // --- PIPELINE FLOW CONTROL ---
    input  logic        i_flush,  // (Thường nối 0, nhưng giữ để đồng bộ)
    input  logic        i_stall,  // (Thường nối 0)

    // --- DATA PATH INPUTS (Từ tầng EX) ---
    input  logic [31:0] PC_EX,
    input  logic [31:0] PCfour_EX,
    input  logic [31:0] instr_EX,      // Instruction
    input  logic [31:0] alu_EX,        // Kết quả tính toán ALU
    input  logic [31:0] rs2_EX,        // Dữ liệu Store (đã qua Forwarding B)
    input  logic [4:0]  rd_addr_EX,    

    // --- CONTROL SIGNALS INPUTS ---
    // Nhóm MEM (LSU)
    input  logic        mem_wren_EX, 
    input  logic        mem_rden_EX,
    input  logic [2:0]  mem_funct3_EX, 

    // Nhóm WB (RegFile)
    input  logic        rd_wren_EX,
    input  logic [1:0]  wb_sel_EX,
    input  logic        i_insn_vld_EX, // [MỚI] Input tín hiệu Valid từ EX

    // ================= OUTPUTS (Sang tầng MEM) =================
    
    // --- DATA PATH OUTPUTS ---
    output logic [31:0] PC_MEM,
    output logic [31:0] PCfour_MEM,
    output logic [31:0] instr_MEM,      
    output logic [31:0] alu_MEM, 
    output logic [31:0] rs2_MEM,        
    output logic [4:0]  rd_addr_MEM,
    output logic        o_insn_vld_MEM, // [MỚI] Output tín hiệu Valid sang MEM

    // --- CONTROL SIGNALS OUTPUTS ---
    output logic        mem_wren_MEM, 
    output logic        mem_rden_MEM,
    output logic [2:0]  mem_funct3_MEM,
    output logic        rd_wren_MEM,
    output logic [1:0]  wb_sel_MEM
);

    // =================================================================
    // 1. THANH GHI PC, PC+4, ALU Result, Store Data (rs2)
    // =================================================================

    reg32 u_reg_pc (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PC_EX), 
        .d_out(PC_MEM)
    );

    reg32 u_reg_pc_four (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PCfour_EX), 
        .d_out(PCfour_MEM)
    );

    reg32 u_reg_alu_res (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(alu_EX), 
        .d_out(alu_MEM)
    );

    reg32 u_reg_rs2 (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(rs2_EX), 
        .d_out(rs2_MEM)
    );

    // =================================================================
    // 2. THANH GHI INSTRUCTION (XỬ LÝ MUX CHO NOP)
    // =================================================================
    
    logic [31:0] instr_in_mux;
    logic        instr_stall_logic;

    // Logic MUX: Nếu Flush -> Chọn NOP (0x13).
    assign instr_in_mux = (i_flush) ? 32'h0000_0013 : instr_EX;

    // Logic Stall: Flush ưu tiên hơn Stall
    assign instr_stall_logic = i_stall & (~i_flush);

    reg32 u_reg_instr (
        .i_clk   (i_clk), 
        .i_reset (i_reset),
        .flush   (1'b0),              // Tắt flush nội bộ
        .stall   (instr_stall_logic), 
        .d_in    (instr_in_mux),      
        .d_out   (instr_MEM)
    );

    // =================================================================
    // 3. THANH GHI RD ADDRESS (5-bit)
    // =================================================================
    logic [31:0] rd_addr_extended_out;
    
    reg32 u_reg_rd_addr (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in({27'b0, rd_addr_EX}), 
        .d_out(rd_addr_extended_out)
    );
    assign rd_addr_MEM = rd_addr_extended_out[4:0];

    // =================================================================
    // 4. THANH GHI CONTROL SIGNALS (GOM NHÓM)
    // =================================================================
    
    logic [31:0] ctrl_packet_in, ctrl_packet_out;
    
    // Đóng gói tín hiệu (Tăng lên 9 bit thực tế + 23 bit padding)
    assign ctrl_packet_in = {
        23'b0,           // Padding (GIẢM 1 bit so với cũ)
        i_insn_vld_EX,   // [8] [MỚI] Tín hiệu Valid từ EX
        wb_sel_EX,       // [7:6]
        rd_wren_EX,      // [5]
        mem_funct3_EX,   // [4:2]
        mem_rden_EX,     // [1]
        mem_wren_EX      // [0]
    };

    reg32 u_reg_control (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(ctrl_packet_in), 
        .d_out(ctrl_packet_out)
    );

    // Giải nén tín hiệu
    assign mem_wren_MEM   = ctrl_packet_out[0];
    assign mem_rden_MEM   = ctrl_packet_out[1];
    assign mem_funct3_MEM = ctrl_packet_out[4:2];
    assign rd_wren_MEM    = ctrl_packet_out[5];
    assign wb_sel_MEM     = ctrl_packet_out[7:6];
    assign o_insn_vld_MEM = ctrl_packet_out[8]; // [MỚI] Output Valid

endmodule