//######################################################################
// MODULE: mem_wb_reg (Structural - LSU Bypass logic)
// Updated: Added PC register & Instruction register for Debugging
//######################################################################
module mem_wb_reg (
    input  logic        i_clk,
    input  logic        i_reset,  // Async Reset
    
    // --- PIPELINE FLOW CONTROL ---
    input  logic        i_flush,  // (Dự phòng, thường là 0)
    input  logic        i_stall,  // (Dự phòng, thường là 0)

    // --- DATA PATH INPUTS (Từ tầng MEM) ---
    input  logic [31:0] PC_MEM,      // PC hiện tại từ tầng MEM
    input  logic [31:0] PCfour_MEM,
    input  logic [31:0] instr_MEM,   // [MỚI] Instruction từ tầng MEM
    input  logic [31:0] alu_MEM, 
    input  logic [31:0] lsu_MEM,     // Dữ liệu đọc từ RAM (đã trễ 1 clk)
    input  logic [4:0]  rd_addr_MEM,    

    // --- CONTROL SIGNALS INPUTS ---
    input  logic        rd_wren_MEM,
    input  logic [1:0]  wb_sel_MEM,
    input  logic        i_insn_vld_MEM, // [MỚI] Input tín hiệu Valid từ MEM

    // ================= OUTPUTS (Sang tầng WB) =================
    
    // --- DATA PATH OUTPUTS ---
    output logic [31:0] PC_WB,       // PC tại tầng WB
    output logic [31:0] PCfour_WB,
    output logic [31:0] instr_WB,    // [MỚI] Instruction tại tầng WB
    output logic [31:0] alu_WB,
    output logic [31:0] lsu_WB,      // Bypass, không qua reg
    output logic [4:0]  rd_addr_WB,
    output logic        o_insn_vld_WB, // [MỚI] Output tín hiệu Valid cuối cùng

    // --- CONTROL SIGNALS OUTPUTS ---
    output logic        rd_wren_WB,
    output logic [1:0]  wb_sel_WB
);

    // =================================================================
    // 1. THANH GHI DỮ LIỆU CẦN CHỐT (PC, PC+4, INSTR, ALU)
    // =================================================================
    
    // Thanh ghi lưu PC
    reg32 u_reg_pc (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PC_MEM), 
        .d_out(PC_WB)
    );

    // Thanh ghi lưu PC+4
    reg32 u_reg_pc_four (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(PCfour_MEM), 
        .d_out(PCfour_WB)
    );

    // 2. THANH GHI INSTRUCTION (XỬ LÝ MUX CHO NOP)
    // =================================================================
    
    logic [31:0] instr_in_mux;
    logic        instr_stall_logic;

    // Logic MUX: Nếu Flush -> Chọn NOP (0x13). Nếu không -> Chọn instr_ID.
    assign instr_in_mux = (i_flush) ? 32'h0000_0013 : instr_MEM;

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
        .d_out   (instr_WB)
    );


    // Thanh ghi lưu ALU Result
    reg32 u_reg_alu_res (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(alu_MEM), 
        .d_out(alu_WB)
    );

    // =================================================================
    // 2. LOGIC BYPASS CHO LSU DATA (QUAN TRỌNG)
    // =================================================================
    // Vì RAM là synchronous read, dữ liệu lsu_data_MEM thực chất đã là 
    // dữ liệu của chu kỳ trước (đúng thời điểm WB).
    // Nếu ta cho qua reg32 nữa, nó sẽ bị trễ thành chu kỳ sau -> Sai.
    // => Dùng assign nối thẳng.
    
    assign lsu_WB = lsu_MEM;

    // =================================================================
    // 3. THANH GHI RD ADDRESS
    // =================================================================
    logic [31:0] rd_addr_extended_out;
    
    reg32 u_reg_rd_addr (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in({27'b0, rd_addr_MEM}), 
        .d_out(rd_addr_extended_out)
    );
    assign rd_addr_WB = rd_addr_extended_out[4:0];

    // =================================================================
    // 4. THANH GHI CONTROL SIGNALS
    // =================================================================
    
    logic [31:0] ctrl_packet_in, ctrl_packet_out;
    
    // Đóng gói tín hiệu (3 bit tổng cộng)
    assign ctrl_packet_in = {
        28'b0,           // Padding (GIẢM 1 bit so với cũ)
        i_insn_vld_MEM,  // [3] [MỚI] Tín hiệu Valid từ MEM
        wb_sel_MEM,      // [2:1]
        rd_wren_MEM      // [0]
    };

    reg32 u_reg_control (
        .i_clk(i_clk), .i_reset(i_reset), .flush(i_flush), .stall(i_stall),
        .d_in(ctrl_packet_in), 
        .d_out(ctrl_packet_out)
    );

    // Giải nén tín hiệu
    assign rd_wren_WB    = ctrl_packet_out[0];
    assign wb_sel_WB     = ctrl_packet_out[2:1];
    assign o_insn_vld_WB = ctrl_packet_out[3]; // [MỚI] Output Valid cuối cùng

endmodule