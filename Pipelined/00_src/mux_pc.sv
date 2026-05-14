
module mux_pc (
    // Inputs (Data)
    input  logic [31:0] PCfour_IF,  // Từ PC+4 [cite: 39]
    input  logic [31:0] alu_EX, // Từ ALU [cite: 50]
    
    // Input (Control)
    input  logic        pc_sel,   // Tín hiệu chọn từ ControlUnit 
    
    // Output
    output logic [31:0] PCnext_IF   // Tới thanh ghi PC 
);

   assign PCnext_IF = (pc_sel) ? alu_EX : PCfour_IF;

endmodule 