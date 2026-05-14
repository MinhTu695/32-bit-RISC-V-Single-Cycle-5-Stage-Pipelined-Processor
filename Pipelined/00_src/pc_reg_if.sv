module pc_reg_if (
    input  logic        i_clk,
    input  logic        i_reset,    // Reset tích cực thấp (Global Reset)
    input  logic        i_stall,    // Tín hiệu Stall từ Hazard Unit
    input  logic [31:0] PCnext_IF,  // Giá trị PC tiếp theo (từ Mux PC)
    output logic [31:0] PC_IF        // Giá trị PC hiện tại
);

    // Sử dụng module reg32 làm lõi lưu trữ
    reg32 u_pc_storage (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        
        // PC thường không cần tín hiệu "flush" về 0 trong lúc chạy 
        // (trừ khi Reset). Khi Branch/Jump, ta nạp địa chỉ mới qua PCnext_IF.
        // Do đó, ta ghim flush = 0.
        .flush   (1'b0),     
        
        .stall   (i_stall),   // Nối tín hiệu stall vào đây [cite: 90]
        .d_in    (PCnext_IF), // Nối input PC vào d_in [cite: 91]
        .d_out   (PC_IF)       // Nối output PC ra d_out [cite: 91]
    );

endmodule