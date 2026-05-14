//######################################################################
// MODULE: mux_wb (Full Logic Gate Style)
// Chức năng: Chọn dữ liệu ghi vào Regfile (WB Stage)
//######################################################################
module mux_wb (
    input  logic [31:0] alu_WB, // Sel = 00
    input  logic [31:0] lsu_WB, // Sel = 01
    input  logic [31:0] PCfour_WB,  // Sel = 10
    input  logic [1:0]  i_wb_sel,   // Tín hiệu chọn
    output logic [31:0] o_wb_data
);
    // Giải mã tín hiệu chọn (Decoder 2-to-3)
    logic is_alu; // 00
    logic is_lsu; // 01
    logic is_pc;  // 10

    // Logic cổng đảo và AND
    assign is_alu = (~i_wb_sel[1]) & (~i_wb_sel[0]); // 00  Các lệnh không nhảy và không truy suất memory
    assign is_lsu = (~i_wb_sel[1]) & ( i_wb_sel[0]); // 01  LOAD 
    assign is_pc  = ( i_wb_sel[1]) & (~i_wb_sel[0]); // 10 JAL và JALR 

    // Output = (ALU & Mask_ALU) | (LSU & Mask_LSU) | (PC & Mask_PC

    assign o_wb_data = (alu_WB & {32{is_alu}}) | (lsu_WB & {32{is_lsu}}) | (PCfour_WB & {32{is_pc}});

endmodule