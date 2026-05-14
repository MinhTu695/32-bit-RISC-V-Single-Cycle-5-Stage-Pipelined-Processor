//######################################################################
// MODULE: if_id_reg (Structural Style using reg32)
//######################################################################
module if_id_reg (
    input  logic        i_clk,
    input  logic        i_reset,  // Active-low asynchronous reset
    input  logic        i_stall,  // Từ Hazard Detection Unit
    input  logic        i_flush,  // Từ Branch Comparator

    // Data Inputs (Từ tầng IF)
    input  logic [31:0] PC_IF,
    input  logic [31:0] PCfour_IF, 
    input  logic [31:0] instr_IF,  // Từ IMEM (Bất đồng bộ)

    // Data Outputs (Sang tầng ID)
    output logic [31:0] PC_ID,
    output logic [31:0] PCfour_ID, 
    output logic [31:0] instr_ID
);

    // =================================================================
    // 1. THANH GHI PC (Lưu giá trị PC hiện tại)
    // =================================================================
    reg32 reg_PC_IF_ID (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .flush    (i_flush), // Flush về 0 khi nhảy
        .stall    (i_stall), // Giữ giá trị khi Load-Use
        .d_in     (PC_IF),
        .d_out    (PC_ID)
    );

    // =================================================================
    // 2. THANH GHI PC+4 (Lưu giá trị PC kế tiếp tuần tự)
    // =================================================================
    reg32 reg_PCfour_IF_ID (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .flush    (i_flush), // Flush về 0 khi nhảy
        .stall    (i_stall), // Giữ giá trị khi Load-Use
        .d_in     (PCfour_IF),
        .d_out    (PCfour_ID)
    );

    // =================================================================
    // 3. THANH GHI INSTRUCTION (QUAN TRỌNG: CÓ THANH GHI + NOP MUX)
    // =================================================================
    
    logic [31:0] instr_data_in;
    logic        instr_stall_ctrl;

    // A. Logic Mux cho Flush: 
    // - Nếu Flush = 1: Ép dữ liệu đầu vào thành NOP (0x00000013).
    // - Nếu Flush = 0: Lấy instruction từ IMEM.
    assign instr_data_in = (i_flush) ? 32'h0000_0013 : instr_IF;

    // B. Logic Stall Controller:
    // - Khi đang Flush: Ta BẮT BUỘC phải ghi NOP vào thanh ghi. -> Không được Stall.
    // - Khi không Flush: Stall hoạt động bình thường theo tín hiệu i_stall.
    assign instr_stall_ctrl = i_stall & (~i_flush);

    // C. Thanh ghi lưu trữ
    reg32 reg_instr (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        
        // Lưu ý: Ta tắt .flush của reg32 (để nó không về 0), 
        // mà dùng Mux ở trên để đưa 0x13 vào.
        .flush    (1'b0),          
        .stall    (instr_stall_ctrl), 
        
        .d_in     (instr_data_in),
        .d_out    (instr_ID)
    );

endmodule