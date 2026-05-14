module forwarding_mux_2 (
    input  logic [31:0] rs2_EX,   // 00
    input  logic [31:0] imm_EX,    // 01
    input  logic [31:0] alu_MEM,  // 10
	 input  logic [31:0] o_wb_data,//11
    input  logic [1:0]  sel_mux2,
    output logic [31:0] out_data
);

always_comb begin
        case (sel_mux2)
            2'b00: out_data = rs2_EX;
            2'b01: out_data = imm_EX;
            2'b10: out_data = alu_MEM;
            2'b11: out_data = o_wb_data; 
            default: out_data = rs2_EX;
        endcase
    end
endmodule