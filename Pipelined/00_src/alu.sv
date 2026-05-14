//****************************************************************

// Module: full_adder 

//****************************************************************

module full_adder_alu (

    input  logic a,b,cin,

    output logic s,cout

);

    assign s = a ^ b ^ cin;

    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule : full_adder_alu



//****************************************************************

// Module: decoder 4 sang 10 

//****************************************************************

module decoder4to11 (

    input  logic [3:0] i_sel,

    input  logic       i_en,

    output logic [10:0] o_decoded

);

    logic [3:0] sel_n;

    assign sel_n = ~i_sel;

    assign o_decoded[ 0] = i_en & sel_n[3] & sel_n[2] & sel_n[1] & sel_n[0]; //0000 add 

    assign o_decoded[ 1] = i_en & sel_n[3] & sel_n[2] & sel_n[1] & i_sel[0]; //0001 sub 

    assign o_decoded[ 2] = i_en & sel_n[3] & sel_n[2] & i_sel[1] & sel_n[0]; //0010 sll 

    assign o_decoded[ 3] = i_en & sel_n[3] & i_sel[2] & sel_n[1] & sel_n[0]; //0100 slt 

    assign o_decoded[ 4] = i_en & sel_n[3] & i_sel[2] & i_sel[1] & sel_n[0]; //0110 sltu

    assign o_decoded[ 5] = i_en & i_sel[3] & sel_n[2] & sel_n[1] & sel_n[0]; //1000 xor

    assign o_decoded[ 6] = i_en & i_sel[3] & sel_n[2] & i_sel[1] & sel_n[0]; //1010 srl

    assign o_decoded[ 7] = i_en & i_sel[3] & sel_n[2] & i_sel[1] & i_sel[0]; //1011 sra

    assign o_decoded[ 8] = i_en & i_sel[3] & i_sel[2] & sel_n[1] & sel_n[0]; //1100 or

    assign o_decoded[ 9] = i_en & i_sel[3] & i_sel[2] & i_sel[1] & sel_n[0]; //1110 and
	 
    assign o_decoded[ 10] = i_en & i_sel[3] & i_sel[2] & i_sel[1] & i_sel[0]; //1111 lui


endmodule: decoder4to11



//****************************************************************

// Module: mux10to1_32bit 

//****************************************************************

module mux11to1_32bit (
    input  logic [3:0]  i_sel,
    input  logic [31:0] i_in [10:0], 
    output logic [31:0] o_y
);
    logic [10:0] decoded_sel;

    decoder4to11 u_dec (
        .i_sel    (i_sel),
        .i_en     (1'b1), 
        .o_decoded(decoded_sel)
    );
    // Logic MUX 10-sang-1 
    always_comb begin
        
         o_y = 32'b0; 
        for (int i = 0; i < 11; i = i + 1) begin
            o_y = o_y | (i_in[i] & {32{decoded_sel[i]}});
        end
    end
endmodule



//================================================================

// CÁC MODULE CON TÍNH TOÁN MỚI

//================================================================



//****************************************************************

// Module: alu_logic_unit (Khối 3)

//****************************************************************

module alu_logic_unit (

    input  logic [31:0] i_op_a,

    input  logic [31:0] i_op_b,

    output logic [31:0] o_and_result,

    output logic [31:0] o_or_result,

    output logic [31:0] o_xor_result

);

    assign o_and_result = i_op_a & i_op_b;

    assign o_or_result  = i_op_a | i_op_b;

    assign o_xor_result = i_op_a ^ i_op_b;

endmodule



//****************************************************************

// Module: alu_shifter_unit (Khối 6)

//****************************************************************

module alu_shifter_unit (

    input  logic [31:0] i_op_a,

    input  logic [31:0] i_op_b,

    output logic [31:0] o_sll_result,

    output logic [31:0] o_srl_result,

    output logic [31:0] o_sra_result

);

    logic [4:0] shift_amount;

    assign shift_amount = i_op_b[4:0];

    

    //--- SLL (Shift Left Logical) ---

    logic [31:0] sll_1, sll_2, sll_4, sll_8;

    logic [31:0] sll_A_1, sll_A_2, sll_A_4, sll_A_8, sll_A_16;

    assign sll_A_1  = {i_op_a[30:0], 1'b0};

    assign sll_1  = (sll_A_1  & {32{shift_amount[0]}}) | (i_op_a & {32{~shift_amount[0]}});

    assign sll_A_2  = {sll_1[29:0],  2'b0};

    assign sll_2  = (sll_A_2  & {32{shift_amount[1]}}) | (sll_1  & {32{~shift_amount[1]}});

    assign sll_A_4  = {sll_2[27:0],  4'b0};

    assign sll_4  = (sll_A_4  & {32{shift_amount[2]}}) | (sll_2  & {32{~shift_amount[2]}});

    assign sll_A_8  = {sll_4[23:0],  8'b0};

    assign sll_8  = (sll_A_8  & {32{shift_amount[3]}}) | (sll_4  & {32{~shift_amount[3]}});

    assign sll_A_16 = {sll_8[15:0],  16'b0};

    assign o_sll_result = (sll_A_16 & {32{shift_amount[4]}}) | (sll_8  & {32{~shift_amount[4]}});

    

    //--- SRL (Shift Right Logical) ---

    logic [31:0] srl_1, srl_2, srl_4, srl_8;

    logic [31:0] srl_A_1, srl_A_2, srl_A_4, srl_A_8, srl_A_16;

    assign srl_A_1  = {1'b0,         i_op_a[31:1]};

    assign srl_1  = (srl_A_1  & {32{shift_amount[0]}}) | (i_op_a & {32{~shift_amount[0]}});

    assign srl_A_2  = {2'b0,       srl_1[31:2]};

    assign srl_2  = (srl_A_2  & {32{shift_amount[1]}}) | (srl_1  & {32{~shift_amount[1]}});

    assign srl_A_4  = {4'b0,       srl_2[31:4]};

    assign srl_4  = (srl_A_4  & {32{shift_amount[2]}}) | (srl_2  & {32{~shift_amount[2]}});

    assign srl_A_8  = {8'b0,       srl_4[31:8]};

    assign srl_8  = (srl_A_8  & {32{shift_amount[3]}}) | (srl_4  & {32{~shift_amount[3]}});

    assign srl_A_16 = {16'b0,      srl_8[31:16]};

    assign o_srl_result = (srl_A_16 & {32{shift_amount[4]}}) | (srl_8  & {32{~shift_amount[4]}});

    

    //--- SRA (Shift Right Arithmetic) ---

    logic [31:0] sra_1, sra_2, sra_4, sra_8;

    logic [31:0] sra_A_1, sra_A_2, sra_A_4, sra_A_8, sra_A_16;

    logic sign_bit;

    assign sign_bit = i_op_a[31]; // Bit dấu

    assign sra_A_1  = {{1{sign_bit}}, i_op_a[31:1]};

    assign sra_1  = (sra_A_1  & {32{shift_amount[0]}}) | (i_op_a & {32{~shift_amount[0]}});

    assign sra_A_2  = {{2{sign_bit}}, sra_1[31:2]};

    assign sra_2  = (sra_A_2  & {32{shift_amount[1]}}) | (sra_1  & {32{~shift_amount[1]}});

    assign sra_A_4  = {{4{sign_bit}}, sra_2[31:4]};

    assign sra_4  = (sra_A_4  & {32{shift_amount[2]}}) | (sra_2  & {32{~shift_amount[2]}});

    assign sra_A_8  = {{8{sign_bit}}, sra_4[31:8]};

    assign sra_8  = (sra_A_8  & {32{shift_amount[3]}}) | (sra_4  & {32{~shift_amount[3]}});

    assign sra_A_16 = {{16{sign_bit}}, sra_8[31:16]};

    assign o_sra_result = (sra_A_16 & {32{shift_amount[4]}}) | (sra_8  & {32{~shift_amount[4]}});

endmodule



//****************************************************************

// Module: alu_add_sub_compare_unit (Khối 4 & 5)

//****************************************************************

module alu_add_sub_compare_unit (

    input  logic [31:0] i_op_a,

    input  logic [31:0] i_op_b,

    input  logic        i_sub_bit, // Tín hiệu điều khiển

    output logic [31:0] o_add_sub_result,

    output logic [31:0] o_slt_result,

    output logic [31:0] o_sltu_result

);

    // 4. Bộ cộng/trừ 32-bit

    logic [32:0] carry_wires;

    assign carry_wires[0] = i_sub_bit; 

    logic [31:0] op_b_modified;

    assign op_b_modified = i_op_b ^ {32{i_sub_bit}};



    genvar i;

    generate

        for (i = 0; i < 32; i = i + 1) begin : fa_gen

            full_adder_alu fa_inst (

                .a    (i_op_a[i]),

                .b    (op_b_modified[i]),

                .cin  (carry_wires[i]),

                .s    (o_add_sub_result[i]),

                .cout (carry_wires[i+1])

            );

        end

    endgenerate



    // 5. Phép so sánh

    logic overflow_bit;

    assign overflow_bit = carry_wires[32] ^ carry_wires[31];

    logic slt_bit;

    assign slt_bit = o_add_sub_result[31] ^ overflow_bit;

    assign o_slt_result = {31'b0, slt_bit};

    

    logic sltu_bit;

    assign sltu_bit = ~carry_wires[32];

    assign o_sltu_result = {31'b0, sltu_bit};

endmodule





//****************************************************************

// Module: alu (Arithmetic Logic Unit) TOP


//****************************************************************

module alu (

    input  logic [31:0] i_op_a,

    input  logic [31:0] i_op_b,

    input  logic [ 3:0] i_alu_op,

    output logic [31:0] o_alu_data

);



    //============================================================

    // 1. KHỐI GIẢI MÃ ĐIỀU KHIỂN

    //============================================================

    logic [10:0] alu_op_decoded;

    decoder4to11 u_alu_decoder (

        .i_sel    (i_alu_op),

        .i_en     (1'b1), 

        .o_decoded(alu_op_decoded)

    );

    

    // Tạo tín hiệu sub_bit cho khối cộng/trừ

    logic sub_bit;

    assign sub_bit = alu_op_decoded[1] | alu_op_decoded[3] | alu_op_decoded[4]; // SUB, SLT, SLTU



    //============================================================

    // 2. KHỞI TẠO CÁC KHỐI TÍNH TOÁN

    //============================================================

    

    // Dây (wires) để giữ 9 kết quả

    logic [31:0] add_sub_result;

    logic [31:0] slt_result;

    logic [31:0] sltu_result;

    logic [31:0] xor_result;

    logic [31:0] or_result;

    logic [31:0] and_result;

    logic [31:0] sll_result;

    logic [31:0] srl_result;

    logic [31:0] sra_result;



    // Khối 3: Logic

    alu_logic_unit u_logic (

        .i_op_a      (i_op_a),

        .i_op_b      (i_op_b),

        .o_and_result(and_result),

        .o_or_result (or_result),

        .o_xor_result(xor_result)

    );



    // Khối 6: Shifter

    alu_shifter_unit u_shifter (

        .i_op_a        (i_op_a),

        .i_op_b        (i_op_b),

        .o_sll_result(sll_result),

        .o_srl_result(srl_result),

        .o_sra_result(sra_result)

    );



    // Khối 4 & 5: Adder/Comparator

    alu_add_sub_compare_unit u_add_sub_comp (

        .i_op_a            (i_op_a),

        .i_op_b            (i_op_b),

        .i_sub_bit         (sub_bit),

        .o_add_sub_result(add_sub_result),

        .o_slt_result    (slt_result),

        .o_sltu_result   (sltu_result)

    );



    //============================================================

    // 7. KHỐI OUTPUT (MUX)

    //============================================================

    

   // Mã hóa 10 kết quả (theo 'decoded_sel') thành 1 mảng
    logic [31:0] result [10:0];
    
    assign result[0] = add_sub_result; // [0] = ADD
    assign result[1] = add_sub_result; // [1] = SUB
    assign result[2] = sll_result;     // [2] = SLL
    assign result[3] = slt_result;     // [3] = SLT
    assign result[4] = sltu_result;    // [4] = SLTU
    assign result[5] = xor_result;     // [5] = XOR
    assign result[6] = srl_result;     // [6] = SRL
    assign result[7] = sra_result;     // [7] = SRA
    assign result[8] = or_result;      // [8] = OR
    assign result[9] = and_result;     // [9] = AND
    assign result[10]=i_op_b;          // [10]= PASS-B (LUI)

    //Khoi tao mux 11 sang 1 de chon data output cua alu

    mux11to1_32bit u_mux_alu_output (

        .i_sel (i_alu_op),

        .i_in  (result),

        .o_y   (o_alu_data)

    );  

    

endmodule : alu