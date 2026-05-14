//######################################################################
// Module: decoder_3to5
// - Module con, chỉ làm nhiệm vụ giải mã 3-bit -> 5-bit one-hot.
//######################################################################
module decoder_3to5 (
    // Input
    input  logic [2:0] i_val, // Giá trị 3-bit (i_instr_type)
    
    // Outputs (one-hot)
    output logic o_sel_I,
    output logic o_sel_S,
    output logic o_sel_B,
    output logic o_sel_U,
    output logic o_sel_J
);

    // Khai báo ENUMs
    localparam IT_ITYPE = 3'b001;
    localparam IT_STYPE = 3'b010;
    localparam IT_BTYPE = 3'b011;
    localparam IT_UTYPE = 3'b100;
    localparam IT_JTYPE = 3'b101;

    // Wires trung gian cho logic XNOR
    logic [2:0] xnor_I, xnor_S, xnor_B, xnor_U, xnor_J;

    // 1. So sánh cho sel_I (i_val == 3'b001)
    assign xnor_I[2] = ~(i_val[2] ^ IT_ITYPE[2]); // (i_val[2] XNOR 0)
    assign xnor_I[1] = ~(i_val[1] ^ IT_ITYPE[1]); // (i_val[1] XNOR 0)
    assign xnor_I[0] = ~(i_val[0] ^ IT_ITYPE[0]); // (i_val[0] XNOR 1)
    assign o_sel_I = xnor_I[2] & xnor_I[1] & xnor_I[0];

    // 2. So sánh cho sel_S (i_val == 3'b010)
    assign xnor_S[2] = ~(i_val[2] ^ IT_STYPE[2]); // (i_val[2] XNOR 0)
    assign xnor_S[1] = ~(i_val[1] ^ IT_STYPE[1]); // (i_val[1] XNOR 1)
    assign xnor_S[0] = ~(i_val[0] ^ IT_STYPE[0]); // (i_val[0] XNOR 0)
    assign o_sel_S = xnor_S[2] & xnor_S[1] & xnor_S[0];

    // 3. So sánh cho sel_B (i_val == 3'b011)
    assign xnor_B[2] = ~(i_val[2] ^ IT_BTYPE[2]); // (i_val[2] XNOR 0)
    assign xnor_B[1] = ~(i_val[1] ^ IT_BTYPE[1]); // (i_val[1] XNOR 1)
    assign xnor_B[0] = ~(i_val[0] ^ IT_BTYPE[0]); // (i_val[0] XNOR 1)
    assign o_sel_B = xnor_B[2] & xnor_B[1] & xnor_B[0];

    // 4. So sánh cho sel_U (i_val == 3'b100)
    assign xnor_U[2] = ~(i_val[2] ^ IT_UTYPE[2]); // (i_val[2] XNOR 1)
    assign xnor_U[1] = ~(i_val[1] ^ IT_UTYPE[1]); // (i_val[1] XNOR 0)
    assign xnor_U[0] = ~(i_val[0] ^ IT_UTYPE[0]); // (i_val[0] XNOR 0)
    assign o_sel_U = xnor_U[2] & xnor_U[1] & xnor_U[0];

    // 5. So sánh cho sel_J (i_val == 3'b101)
    assign xnor_J[2] = ~(i_val[2] ^ IT_JTYPE[2]); // (i_val[2] XNOR 1)
    assign xnor_J[1] = ~(i_val[1] ^ IT_JTYPE[1]); // (i_val[1] XNOR 0)
    assign xnor_J[0] = ~(i_val[0] ^ IT_JTYPE[0]); // (i_val[0] XNOR 1)
    assign o_sel_J = xnor_J[2] & xnor_J[1] & xnor_J[0];

endmodule 
//######################################################################
// Module: imm_gen_mux
//######################################################################
module imm_gen_mux (
    // Inputs (Data)
    input  logic [31:0] i_imm_i,
    input  logic [31:0] i_imm_s,
    input  logic [31:0] i_imm_b,
    input  logic [31:0] i_imm_u,
    input  logic [31:0] i_imm_j,
    
    // Input (Control)
    input  logic [2:0]  i_instr_type, 
    
    // Output
    output logic [31:0] o_imm_data
);

    // Wires trung gian (đầu ra của decoder)
    logic sel_I, sel_S, sel_B, sel_U, sel_J;

    // -------------------------------------------------------------------
    // I. KHỐI DECODER (Instantiate)
    // -------------------------------------------------------------------
    decoder_3to5 u_decoder (
        .i_val     (i_instr_type),
        
        .o_sel_I   (sel_I),
        .o_sel_S   (sel_S),
        .o_sel_B   (sel_B),
        .o_sel_U   (sel_U),
        .o_sel_J   (sel_J)
    );

    // -------------------------------------------------------------------
    // II. KHỐI MUX (Logic AND-OR 32-bit)
    // -------------------------------------------------------------------
    
    assign o_imm_data = 
        (i_imm_i & {32{sel_I}}) |
        (i_imm_s & {32{sel_S}}) |
        (i_imm_b & {32{sel_B}}) |
        (i_imm_u & {32{sel_U}}) |
        (i_imm_j & {32{sel_J}});

endmodule 
//######################################################################
// Module: imm_gen (Top-Level)
//######################################################################
module imm_gen (
    // Inputs
    input  logic [31:0] i_instr,
    input  logic [2:0]  i_instr_type, 
    
    // Output
    output logic [31:0] o_imm_data
);

    // -------------------------------------------------------------------
    // I. PHẦN DATAPATH (Giữ lại ở top-level)
    // -------------------------------------------------------------------
    
    localparam SIGN_BITS_I = 20; 
    localparam SIGN_BITS_S = 20; 
    localparam SIGN_BITS_B = 19;
    localparam SIGN_BITS_J = 11; 
    
    logic sign_bit;
    assign sign_bit = i_instr[31];
    
    logic [31:0] imm_I, imm_S, imm_B, imm_U, imm_J;

    assign imm_I = {{SIGN_BITS_I{sign_bit}}, i_instr[31:20]};
    assign imm_S = {{SIGN_BITS_S{sign_bit}}, i_instr[31:25], i_instr[11:7]};
    assign imm_B = {{SIGN_BITS_B{sign_bit}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
    assign imm_U = {i_instr[31:12], 12'b0};
    assign imm_J = {{SIGN_BITS_J{sign_bit}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

    // -------------------------------------------------------------------
    // II. PHẦN MUX 
    // -------------------------------------------------------------------

    imm_gen_mux u_mux (
        .i_imm_i      (imm_I),          
        .i_imm_s      (imm_S),          
        .i_imm_b      (imm_B),          
        .i_imm_u      (imm_U),          
        .i_imm_j      (imm_J),          
        
        .i_instr_type (i_instr_type), 
        
        .o_imm_data   (o_imm_data)      
    );

endmodule 