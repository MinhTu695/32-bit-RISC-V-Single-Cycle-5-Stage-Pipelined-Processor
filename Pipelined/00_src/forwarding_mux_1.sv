module forwarding_mux_1 (
    input  logic [31:0] rs1_EX,   // 00: Data gốc
    input  logic [31:0] PC_EX, 
    input  logic [31:0] alu_MEM,  // 10: Forward từ alu tang MEM
    input  logic [1:0]  sel_mux1,      // Tín hiệu chọn lấy từ forwarding_unit
	 input  logic [31:0] o_wb_data,
    output logic [31:0] out_data
);



    
always_comb begin
        case (sel_mux1)
            2'b00: out_data = rs1_EX;
            2'b01: out_data = PC_EX;
            2'b10: out_data = alu_MEM;
            2'b11: out_data = o_wb_data; // [MỚI]
            default: out_data = rs1_EX;
        endcase
    end
endmodule
