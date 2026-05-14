module reg32 (
    input  logic        i_clk,
    input  logic        i_reset,   // Active low asynchronous reset
    input  logic        flush,     // Flush ưu tiên cao hơn stall
    input  logic        stall,     // Stall giữ nguyên dữ liệu
    input  logic [31:0] d_in,
    output logic [31:0] d_out
);

    logic [31:0] next_q;

    // ---------------------------------------
    // 1) Tính giá trị sẽ được nạp vào FF
    // ---------------------------------------
    always_comb begin
        if (flush)           // ƯU TIÊN 1: Flush → đẩy 0 vào FF
            next_q = 32'b0;
        else if (stall)      // ƯU TIÊN 2: Stall → giữ nguyên
            next_q = d_out;  // feedback output
        else                 // Bình thường → nạp d_in
            next_q = d_in;
    end

    // ---------------------------------------
    // 2) FF thật sự
    // ---------------------------------------
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset)
            d_out <= 32'b0;
        else
            d_out <= next_q;
    end

endmodule
