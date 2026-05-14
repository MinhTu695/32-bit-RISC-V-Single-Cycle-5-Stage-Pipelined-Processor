//######################################################################

// MODULE ĐỈNH: lsu (Load-Store Unit)

//######################################################################

module lsu (

     input  logic        i_clk,

     input  logic        i_reset,

     input  logic [31:0] i_lsu_addr,

     input  logic [31:0] i_st_data,

     input  logic        i_lsu_wren,

     input  logic [2:0]  i_mem_funct3,

     output logic [31:0] o_ld_data,

     output logic [31:0] o_io_ledr,

     output logic [31:0] o_io_ledg,

     output logic [6:0]  o_io_hex0,

     output logic [6:0]  o_io_hex1,

     output logic [6:0]  o_io_hex2,

     output logic [6:0]  o_io_hex3,

     output logic [6:0]  o_io_hex4,

     output logic [6:0]  o_io_hex5,

     output logic [6:0]  o_io_hex6,

     output logic [6:0]  o_io_hex7, 

     output logic [31:0] o_io_lcd,

     input  logic [31:0] i_io_sw

);



    // Tín hiệu nội bộ trong module

    logic mem_sel, ledr_sel, ledg_sel, hex03_sel, hex47_sel, lcd_sel, sw_sel;

    logic [31:0] mem_rdata_raw, mem_data_processed, sw_data_from_buffer;

    logic [31:0] ledr_data_readback, ledg_data_readback, hex03_data_readback, hex47_data_readback, lcd_data_readback;

    logic mem_wren;
    logic [3:0]  mem_bmask;
   logic [31:0] o_wdata;
   logic [31:0] raw_ld_data;

  // ============================================================
    logic [1:0] r_addr_bits_pipe;
    logic [2:0] r_mem_funct3_pipe; 
	 
	 // [THÊM] Pipeline registers cho các tín hiệu Select I/O
    logic r_mem_sel_pipe, r_sw_sel_pipe;
    logic r_ledr_sel_pipe, r_ledg_sel_pipe;
    logic r_hex03_sel_pipe, r_hex47_sel_pipe, r_lcd_sel_pipe;

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
            r_addr_bits_pipe  <= 2'b00;
            r_mem_funct3_pipe <= 3'b000;
            
            // [THÊM] Reset các tín hiệu pipe
            r_mem_sel_pipe    <= 1'b0;
            r_sw_sel_pipe     <= 1'b0;
            r_ledr_sel_pipe   <= 1'b0;
            r_ledg_sel_pipe   <= 1'b0;
            r_hex03_sel_pipe  <= 1'b0;
            r_hex47_sel_pipe  <= 1'b0;
            r_lcd_sel_pipe    <= 1'b0;
        end else begin
            r_addr_bits_pipe  <= i_lsu_addr[1:0];
            r_mem_funct3_pipe <= i_mem_funct3;

            // [THÊM] Lưu trạng thái select sang chu kỳ sau (WB)
            r_mem_sel_pipe    <= mem_sel;
            r_sw_sel_pipe     <= sw_sel;
            r_ledr_sel_pipe   <= ledr_sel;
            r_ledg_sel_pipe   <= ledg_sel;
            r_hex03_sel_pipe  <= hex03_sel;
            r_hex47_sel_pipe  <= hex47_sel;
            r_lcd_sel_pipe    <= lcd_sel;
        end
    end

    //============================================================

    // KHỞI TẠO 7 KHỐI CON

    //============================================================



    // 1. KHỐI DECODER (MUX bên trái)

    lsu_decoder u_decoder (

         .i_lsu_addr (i_lsu_addr),

         .o_mem_sel  (mem_sel),   

			.o_ledr_sel (ledr_sel), 

			.o_ledg_sel (ledg_sel),

         .o_hex03_sel(hex03_sel), 

			.o_hex47_sel(hex47_sel),

			.o_lcd_sel  (lcd_sel),

         .o_sw_sel   (sw_sel)

    );



    // 2. KHỐI OUTPUT BUFFER (Ghi ra LED/LCD)

    lsu_output_buffer u_output_buffer (

         .i_clk       (i_clk),         

         .i_reset     (i_reset),

         .i_lsu_wren  (i_lsu_wren),    

         .i_wdata   (o_wdata),

			.io_bmask (mem_bmask),

         .i_ledr_sel  (ledr_sel),      

			.i_ledg_sel  (ledg_sel),

         .i_hex03_sel (hex03_sel),     

			.i_hex47_sel (hex47_sel),

         .i_lcd_sel   (lcd_sel),

         .o_io_ledr  (o_io_ledr),   

			.o_io_ledg  (o_io_ledg),

         .o_io_hex0 (o_io_hex0),

         .o_io_hex1 (o_io_hex1),

         .o_io_hex2 (o_io_hex2),

         .o_io_hex3 (o_io_hex3),

         .o_io_hex4 (o_io_hex4),

         .o_io_hex5 (o_io_hex5),

         .o_io_hex6 (o_io_hex6),

         .o_io_hex7 (o_io_hex7),    

			.o_io_lcd   (o_io_lcd),

         .o_ledr_data  (ledr_data_readback),

         .o_ledg_data  (ledg_data_readback),

         .o_hex03_data (hex03_data_readback),

         .o_hex47_data (hex47_data_readback),

         .o_lcd_data   (lcd_data_readback)

    );

    

    // 3. KHỐI INPUT BUFFER (Đọc từ SW)

    lsu_input_buffer u_input_buffer (

         .i_io_sw   (i_io_sw),

         .o_sw_data (sw_data_from_buffer)

    );

    

    // 4a. KHỐI TIỀN XỬ LÝ STORE (Tạo mem_bmask)

    lsu_store_preprocessor u_store_preproc (

        .i_st_data    (i_st_data),

		  .i_lsu_wren   (i_lsu_wren),

        .i_mem_funct3 (i_mem_funct3),

        .i_addr_bits  (i_lsu_addr[1:0]),

        .o_mem_bmask  (mem_bmask),

        .o_wdata      (o_wdata)

    );

    

    // 4b. Khởi tạo D$ (Memory)

    assign mem_wren = mem_sel & i_lsu_wren;

    memory mem_inst (

         .i_clk   (i_clk),   

			.i_reset (i_reset), 

			.i_addr  (i_lsu_addr[15:2]),

         .i_wdata (o_wdata), 

			.i_bmask (mem_bmask), 

			.i_wren  (mem_wren),

         .o_rdata (mem_rdata_raw) 

    );



    // 5. KHỐI LOAD PROCESSOR (Hậu xử lý D$)

    lsu_load_processor u_load_processor (

         .i_raw_data     (raw_ld_data),

         .i_lsu_addr_bits  (r_addr_bits_pipe),

         .i_mem_funct3     (r_mem_funct3_pipe),

         .o_processed_data (o_ld_data)

    );



    // 6. KHỐI MUX ĐỌC (MUX bên phải)

    lsu_read_mux u_read_mux (

			.i_mem_sel    (r_mem_sel_pipe),   
         .i_sw_sel     (r_sw_sel_pipe),
         .i_ledr_sel   (r_ledr_sel_pipe),
         .i_ledg_sel   (r_ledg_sel_pipe),
         .i_hex03_sel  (r_hex03_sel_pipe),
         .i_hex47_sel  (r_hex47_sel_pipe),
         .i_lcd_sel    (r_lcd_sel_pipe),

         .i_raw_mem_data       (mem_rdata_raw),

         .i_sw_data            (sw_data_from_buffer),

         .i_ledr_readback      (ledr_data_readback),

         .i_ledg_readback      (ledg_data_readback),

         .i_hex03_readback     (hex03_data_readback),

         .i_hex47_readback     (hex47_data_readback),

         .i_lcd_readback       (lcd_data_readback),

         .raw_ld_data            (raw_ld_data)

    );



endmodule

//######################################################################
// Module: memory (D$) 
//######################################################################
module memory (
    input  logic        i_clk,
    input  logic        i_reset,      // Không dùng reset để xóa RAM, chỉ để giữ interface
    input  logic [13:0] i_addr,       // Đã là Word Address (tương ứng 16KB dòng)
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_bmask,
    input  logic        i_wren,
    output logic [31:0] o_rdata
);

    // Khai báo mảng nhớ 64KB (16384 từ nhớ x 32 bit)
    logic [31:0] mem_array [0:1]; 

    initial begin
        // [THÊM] Khởi tạo về 0 cho sạch
        for (int i = 0; i <= 1; i++) begin
            mem_array[i] = 32'h0;
        end
        $readmemh("isa_4b.hex", mem_array);
    end
    // 2. SYNCHRONOUS READ (Đọc đồng bộ theo Clock) 
    always_ff @(posedge i_clk) begin
        o_rdata <= mem_array[i_addr];
    end

    // 3. SYNCHRONOUS WRITE (Ghi đồng bộ theo Clock)
    always_ff @(posedge i_clk) begin
        // Bỏ logic Reset toàn bộ mảng ở đây để tránh lỗi tổng hợp
        if (i_wren) begin 
            // Dùng trực tiếp i_addr làm chỉ số index
            if (i_bmask[0]) mem_array[i_addr][7:0]   <= i_wdata[7:0];
            if (i_bmask[1]) mem_array[i_addr][15:8]  <= i_wdata[15:8];
            if (i_bmask[2]) mem_array[i_addr][23:16] <= i_wdata[23:16];
            if (i_bmask[3]) mem_array[i_addr][31:24] <= i_wdata[31:24];
        end
    end

endmodule


//######################################################################

// HELPER MODULE 1: decoder_2to4

//######################################################################

module decoder_2to4 (

    input  logic [1:0] i_sel,

    input  logic       i_en,

    output logic [3:0] o_decoded

);

    logic [1:0] sel_n;

    assign sel_n = ~i_sel;

    assign o_decoded[0] = i_en & sel_n[1] & sel_n[0]; // 00

    assign o_decoded[1] = i_en & sel_n[1] & i_sel[0]; // 01

    assign o_decoded[2] = i_en & i_sel[1] & sel_n[0]; // 10

    assign o_decoded[3] = i_en & i_sel[1] & i_sel[0]; // 11

endmodule



//######################################################################

// HELPER MODULE 2: mux2to1_Nbit (Tham số hóa)

//######################################################################

module mux2to1_Nbit #(

    parameter WIDTH = 16 // Giá trị mặc định

)(

    input  logic [WIDTH-1:0] i_in0,

    input  logic [WIDTH-1:0] i_in1,

    input  logic             i_sel,

    output logic [WIDTH-1:0] o_y

);

    logic sel_n;

    logic [WIDTH-1:0] anded_0, anded_1;

    assign sel_n = ~i_sel;

    assign anded_0 = i_in0 & {WIDTH{sel_n}};

    assign anded_1 = i_in1 & {WIDTH{i_sel}};

    assign o_y = anded_0 | anded_1;

endmodule



//######################################################################

// HELPER MODULE 3: mux4to1_Nbit (Tham số hóa)

//######################################################################

module mux4to1_Nbit #(

    parameter WIDTH = 8 // Giá trị mặc định

)(

    input  logic [WIDTH-1:0] i_in0, i_in1, i_in2, i_in3,

    input  logic [1:0]       i_sel,

    output logic [WIDTH-1:0] o_y

);

    logic [3:0] decoded_sel;

    decoder_2to4 u_dec (

        .i_sel    (i_sel),

        .i_en     (1'b1),

        .o_decoded(decoded_sel)

    );

    

    logic [WIDTH-1:0] anded_buses [3:0];

    assign anded_buses[0] = i_in0 & {WIDTH{decoded_sel[0]}};

    assign anded_buses[1] = i_in1 & {WIDTH{decoded_sel[1]}};

    assign anded_buses[2] = i_in2 & {WIDTH{decoded_sel[2]}};

    assign anded_buses[3] = i_in3 & {WIDTH{decoded_sel[3]}};

    

    assign o_y = anded_buses[0] | anded_buses[1] | anded_buses[2] | anded_buses[3];

endmodule



//######################################################################

// HELPER MODULE 4: decoder_3to5 (Giải mã funct3 Load)

//######################################################################

module decoder_3to5_lsu (

    input  logic [2:0] i_sel, // i_mem_funct3

    input  logic       i_en,

    output logic [4:0] o_decoded // [0]=is_lb, [1]=is_lh, [2]=is_lw, [3]=is_lbu, [4]=is_lhu

);

    logic [2:0] sel_n;

    assign sel_n = ~i_sel;

    assign o_decoded[0] = i_en & sel_n[2] & sel_n[1] & sel_n[0]; // 000

    assign o_decoded[1] = i_en & sel_n[2] & sel_n[1] & i_sel[0]; // 001

    assign o_decoded[2] = i_en & sel_n[2] & i_sel[1] & sel_n[0]; // 010

    assign o_decoded[3] = i_en & i_sel[2] & sel_n[1] & sel_n[0]; // 100

    assign o_decoded[4] = i_en & i_sel[2] & sel_n[1] & i_sel[0]; // 101

endmodule



//######################################################################

// HELPER MODULE 5: mux5to1_32bit_funct3 (MUX 5-to-1 dùng funct3)

//######################################################################

module mux5to1_32bit_funct3 (

    input  logic [31:0] i_in0, // lb_data

    input  logic [31:0] i_in1, // lh_data

    input  logic [31:0] i_in2, // lw_data

    input  logic [31:0] i_in3, // lbu_data

    input  logic [31:0] i_in4, // lhu_data

    input  logic [2:0]  i_sel, // Tín hiệu 3-bit funct3

    output logic [31:0] o_y

);

    logic [4:0]  decoded_sel;



    // 1. Giải mã 3-bit funct3 thành 5-bit one-hot

    decoder_3to5_lsu u_dec_internal (

        .i_sel    (i_sel),

        .i_en     (1'b1), // Luôn bật

        .o_decoded(decoded_sel)

    );



    // 2. Logic AND-OR

    logic [31:0] anded_buses [4:0];

    assign anded_buses[0] = i_in0 & {32{decoded_sel[0]}};

    assign anded_buses[1] = i_in1 & {32{decoded_sel[1]}};

    assign anded_buses[2] = i_in2 & {32{decoded_sel[2]}};

    assign anded_buses[3] = i_in3 & {32{decoded_sel[3]}};

    assign anded_buses[4] = i_in4 & {32{decoded_sel[4]}};

    

    assign o_y = anded_buses[0] | anded_buses[1] | anded_buses[2] | 

                 anded_buses[3] | anded_buses[4];

endmodule



//######################################################################

// HELPER MODULE 6: mux7to1_32bit (MUX one-hot)

//######################################################################

module mux7to1_32bit (

    input  logic [31:0] i_in0, i_in1, i_in2, i_in3, i_in4, i_in5, i_in6,

    input  logic        i_sel0, i_sel1, i_sel2, i_sel3, i_sel4, i_sel5, i_sel6,

    output logic [31:0] o_y

);

    logic [31:0] anded_buses [6:0];

    assign anded_buses[0] = i_in0 & {32{i_sel0}};

    assign anded_buses[1] = i_in1 & {32{i_sel1}};

    assign anded_buses[2] = i_in2 & {32{i_sel2}};

    assign anded_buses[3] = i_in3 & {32{i_sel3}};

    assign anded_buses[4] = i_in4 & {32{i_sel4}};

    assign anded_buses[5] = i_in5 & {32{i_sel5}};

    assign anded_buses[6] = i_in6 & {32{i_sel6}};

    

    assign o_y = anded_buses[0] | anded_buses[1] | anded_buses[2] |

                 anded_buses[3] | anded_buses[4] | anded_buses[5] |

                 anded_buses[6];

endmodule



//######################################################################

// HELPER MODULE 7: reg8_we (Thanh ghi 8-bit có WE)

//######################################################################

module reg8_we (

    input  logic       i_clk,

    input  logic       i_reset, // Active-low reset

    input  logic       i_we,    // Write enable

    input  logic [7:0] i_d,     // Dữ liệu 8-bit

    output logic [7:0] o_q

);

    always_ff @(posedge i_clk or negedge i_reset) begin

        if (!i_reset)

            o_q <= 8'b0;

        else if (i_we)

            o_q <= i_d;

    end

endmodule



//######################################################################

// MODULE CON 1: lsu_decoder (Bộ giải mã địa chỉ)

//######################################################################

module lsu_decoder (

     input  logic [31:0] i_lsu_addr,

     output logic        o_mem_sel,

     output logic        o_ledr_sel,

     output logic        o_ledg_sel,

     output logic        o_hex03_sel,

     output logic        o_hex47_sel,

     output logic        o_lcd_sel,

     output logic        o_sw_sel

);

     localparam logic [31:0] MEM_BASE   = 32'h0000_0000;

     localparam logic [31:0] LEDR_BASE  = 32'h1000_0000;

     localparam logic [31:0] LEDG_BASE  = 32'h1000_1000;

     localparam logic [31:0] HEX03_BASE = 32'h1000_2000;

     localparam logic [31:0] HEX47_BASE = 32'h1000_3000;

     localparam logic [31:0] LCD_BASE   = 32'h1000_4000;

     localparam logic [31:0] SW_BASE    = 32'h1001_0000;



     always_comb begin

         logic mem_sel_nor_in;

         logic ledr_nor_in, ledg_nor_in, hex03_nor_in, hex47_nor_in, lcd_nor_in, sw_nor_in;

        

         mem_sel_nor_in = 1'b0;

         for (int i = 16; i <= 31; i = i + 1) begin

             mem_sel_nor_in = mem_sel_nor_in | i_lsu_addr[i];

         end

         o_mem_sel = ~mem_sel_nor_in;

        

         ledr_nor_in = 1'b0;

         ledg_nor_in = 1'b0;

         hex03_nor_in = 1'b0;

         hex47_nor_in = 1'b0;

         lcd_nor_in = 1'b0;

         sw_nor_in = 1'b0;

         for (int i = 12; i <= 31; i = i + 1) begin

             ledr_nor_in  = ledr_nor_in  | (i_lsu_addr[i] ^ LEDR_BASE[i]);// dùng xor bit-wise để kiểm tra logic 

             ledg_nor_in  = ledg_nor_in  | (i_lsu_addr[i] ^ LEDG_BASE[i]);

             hex03_nor_in = hex03_nor_in | (i_lsu_addr[i] ^ HEX03_BASE[i]);

             hex47_nor_in = hex47_nor_in | (i_lsu_addr[i] ^ HEX47_BASE[i]);

             lcd_nor_in   = lcd_nor_in   | (i_lsu_addr[i] ^ LCD_BASE[i]);

             sw_nor_in    = sw_nor_in    | (i_lsu_addr[i] ^ SW_BASE[i]);

         end

        

         o_ledr_sel  = ~ledr_nor_in;// do kết quả xor bị ngược với logic kiểm tra bằng (giống ra 0 khác ra 1)

         o_ledg_sel  = ~ledg_nor_in;

         o_hex03_sel = ~hex03_nor_in;

         o_hex47_sel = ~hex47_nor_in;

         o_lcd_sel   = ~lcd_nor_in;

         o_sw_sel    = ~sw_nor_in;

     end

endmodule



//######################################################################

// MODULE CON 2: lsu_output_buffer (Khối Ghi ra I/O) 

//######################################################################

module lsu_output_buffer (

    input  logic       i_clk,

    input  logic       i_reset,

    input  logic       i_lsu_wren,

    input  logic [31:0] i_wdata,// data cho câu lệnh store lấy từ output bộ tiền xử lí

    input  logic [3:0] io_bmask,

    input  logic       i_ledr_sel,

    input  logic       i_ledg_sel,

    input  logic       i_hex03_sel,

    input  logic       i_hex47_sel,

    input  logic       i_lcd_sel,

     output logic [31:0] o_io_ledr,

     output logic [31:0] o_io_ledg,

     output logic [6:0]  o_io_hex0,

     output logic [6:0]  o_io_hex1,

     output logic [6:0]  o_io_hex2,

     output logic [6:0]  o_io_hex3,

     output logic [6:0]  o_io_hex4,

     output logic [6:0]  o_io_hex5,

     output logic [6:0]  o_io_hex6,

     output logic [6:0]  o_io_hex7, 

     output logic [31:0] o_io_lcd,

     output logic [31:0] o_ledr_data,

     output logic [31:0] o_ledg_data,

     output logic [31:0] o_hex03_data,

     output logic [31:0] o_hex47_data,

     output logic [31:0] o_lcd_data

);

	// write enable cho các thanh ghi ngoại vi
    logic [3:0] ledr_we, ledg_we, hex03_we, hex47_we, lcd_we;

	 // mảng 4 giá trị 8bit để có thể truy cập vào từng 7segment
    logic [7:0] ledr_q[3:0], ledg_q[3:0], hex03_q[3:0], hex47_q[3:0], lcd_q[3:0];



    // --- LOGIC MỚI: DỮ LIỆU I/O ĐÃ DỊCH (SHIFTER) ---

    logic [31:0] wdata_to_io;
	 assign wdata_to_io = i_wdata;



    // 3. Tạo 20 tín hiệu Write Enable (Tổ hợp)

    always_comb begin

        for (int i = 0; i < 4; i = i + 1) begin 

            ledr_we[i]  = i_ledr_sel  & io_bmask[i] & i_lsu_wren;

            ledg_we[i]  = i_ledg_sel  & io_bmask[i] & i_lsu_wren;

            hex03_we[i] = i_hex03_sel & io_bmask[i] & i_lsu_wren;

            hex47_we[i] = i_hex47_sel & io_bmask[i] & i_lsu_wren;

            lcd_we[i]   = i_lcd_sel   & io_bmask[i] & i_lsu_wren;

        end

    end



    // 4. Khối 20 Thanh ghi 8-bit (Tuần tự)
	 
    genvar i;

    generate

        for (i = 0; i < 4; i = i + 1) begin : GEN_IO_REGS

      
            reg8_we u_ledr_reg (

                .i_clk(i_clk), 

					 .i_reset(i_reset),

                .i_we(ledr_we[i]),

                .i_d(wdata_to_io[i*8 +: 8]), 

					 .o_q(ledr_q[i])

            );

            reg8_we u_ledg_reg (

                .i_clk(i_clk), 

					 .i_reset(i_reset),

                .i_we(ledg_we[i]),

                .i_d(wdata_to_io[i*8 +: 8]), 

					 .o_q(ledg_q[i])

            );

            reg8_we u_hex03_reg (

                .i_clk(i_clk), 

					 .i_reset(i_reset),

                .i_we(hex03_we[i]),

                .i_d(wdata_to_io[i*8 +: 8]), 

					 .o_q(hex03_q[i])

            );

            reg8_we u_hex47_reg (

                .i_clk(i_clk), 

					 .i_reset(i_reset),

                .i_we(hex47_we[i]),

                .i_d(wdata_to_io[i*8 +: 8]), 

					 .o_q(hex47_q[i])

            );

            reg8_we u_lcd_reg (

                .i_clk(i_clk), 

					 .i_reset(i_reset),

                .i_we(lcd_we[i]),

                .i_d(wdata_to_io[i*8 +: 8]), 

					 .o_q(lcd_q[i])

            );

        end

    endgenerate

    

    // 5. Gán cổng đầu ra (Tổ hợp) - GIỮ NGUYÊN

    assign o_io_ledr = {ledr_q[3], ledr_q[2], ledr_q[1], ledr_q[0]};

    assign o_io_ledg = {ledg_q[3], ledg_q[2], ledg_q[1], ledg_q[0]};

    assign o_io_lcd  = {lcd_q[3],  lcd_q[2],  lcd_q[1],  lcd_q[0]};

    assign o_io_hex0 = hex03_q[0][6:0]; // Nối thanh ghi 0

    assign o_io_hex1 = hex03_q[1][6:0]; // Nối thanh ghi 1

    assign o_io_hex2 = hex03_q[2][6:0]; // Nối thanh ghi 2

    assign o_io_hex3 = hex03_q[3][6:0]; // Nối thanh ghi 3

    assign o_io_hex4 = hex47_q[0][6:0]; // Nối thanh ghi 4

    assign o_io_hex5 = hex47_q[1][6:0]; // Nối thanh ghi 5

    assign o_io_hex6 = hex47_q[2][6:0]; // Nối thanh ghi 6

    assign o_io_hex7 = hex47_q[3][6:0]; // Nối thanh ghi 7

    assign o_ledr_data  = {ledr_q[3],  ledr_q[2],  ledr_q[1],  ledr_q[0]};

    assign o_ledg_data  = {ledg_q[3],  ledg_q[2],  ledg_q[1],  ledg_q[0]};

    assign o_hex03_data = {hex03_q[3], hex03_q[2], hex03_q[1], hex03_q[0]};

    assign o_hex47_data = {hex47_q[3], hex47_q[2], hex47_q[1], hex47_q[0]};

    assign o_lcd_data   = {lcd_q[3],   lcd_q[2],   lcd_q[1],   lcd_q[0]};

endmodule



//######################################################################

// MODULE CON 3: lsu_input_buffer (Khối Đọc từ I/O)

//######################################################################

module lsu_input_buffer (

     input  logic [31:0] i_io_sw,

     output logic [31:0] o_sw_data

);

     assign o_sw_data = i_io_sw;

endmodule



//######################################################################

// MODULE CON 4: lsu_load_processor (Hậu xử lý D$)

//######################################################################

module lsu_load_processor (

     input  logic [31:0] i_raw_data,

     input  logic [1:0]  i_lsu_addr_bits,

     input  logic [2:0]  i_mem_funct3,

     output logic [31:0] o_processed_data

);

		// tín hiệu nội để dễ thao tác
     logic [7:0]  b0, b1, b2, b3;

     logic [15:0] h0, h1;

     logic [7:0]  selected_byte;

     logic [15:0] selected_half;

     logic [31:0] lb_data, lbu_data, lh_data, lhu_data, lw_data;

     

     assign b0 = i_raw_data[7:0];   assign b1 = i_raw_data[15:8];

     assign b2 = i_raw_data[23:16]; assign b3 = i_raw_data[31:24];

     assign h0 = i_raw_data[15:0];  assign h1 = i_raw_data[31:16];


     // Mux chọn byte cần load , bit sel là 2 địa chỉ cuối của địa chỉ truy cập
     mux4to1_Nbit #(.WIDTH(8)) u_mux_byte (

        .i_in0 (b0), 

        .i_in1 (b1), 

		  .i_in2 (b2), 

		  .i_in3 (b3),

        .i_sel (i_lsu_addr_bits[1:0]),

        .o_y   (selected_byte)

     );

     
		// mux chọn half word trên hay dưới , bit sel là địa bit 1 của địa chỉ truy cập 
     mux2to1_Nbit #(.WIDTH(16)) u_mux_half (

        .i_in0 (h0), 

		  .i_in1 (h1),

        .i_sel (i_lsu_addr_bits[1]),

        .o_y   (selected_half)

     );// output mux này cho 1 trong 2 loại half word 

 
 // xử lí logic trước khi qua mux 

     assign lw_data  = i_raw_data;

     assign lb_data  = {{24{selected_byte[7]}}, selected_byte};

     assign lbu_data = {{24'b0},                selected_byte};

     assign lh_data  = {{16{selected_half[15]}}, selected_half};

     assign lhu_data = {{16'b0},                 selected_half};



     // Khởi tạo MUX 5-to-1 cuối cùng tích hợp decoder

     mux5to1_32bit_funct3 u_final_mux (

        .i_in0 (lb_data),

        .i_in1 (lh_data),

        .i_in2 (lw_data),

        .i_in3 (lbu_data),

        .i_in4 (lhu_data),

        .i_sel (i_mem_funct3), // Nối trực tiếp 3-bit funct3 vì đã có decoder chuyển thành bit sel one hot phân biệt sb sh sw sbu shu

        .o_y   (o_processed_data)

     );

     

endmodule



//######################################################################

// MODULE CON 5: lsu_read_mux chọn data thô chưa xử lí từ mem và ngoại vi , dùng output decoder làm bit select sau đó data thô này qua bộ tiền xử lí để load về ngoại vi hay thanh ghi đích

//######################################################################

module lsu_read_mux (

    input  logic        i_mem_sel,

    input  logic        i_sw_sel,

    input  logic        i_ledr_sel,

    input  logic        i_ledg_sel,

    input  logic        i_hex03_sel,

    input  logic        i_hex47_sel,

    input  logic        i_lcd_sel,

    input  logic [31:0] i_raw_mem_data,

    input  logic [31:0] i_sw_data,

    input  logic [31:0] i_ledr_readback,

    input  logic [31:0] i_ledg_readback,

    input  logic [31:0] i_hex03_readback,

    input  logic [31:0] i_hex47_readback,

    input  logic [31:0] i_lcd_readback,

    output logic [31:0] raw_ld_data

);

   // 1. MUX ĐỌC THÔ (7-to-1) đã có select one-hot từ lsu_decoder nên k cần thêm decoder

    mux7to1_32bit u_mux_raw (

        .i_in0(i_raw_mem_data),

        .i_in1(i_sw_data),

        .i_in2(i_ledr_readback),

        .i_in3(i_ledg_readback),

        .i_in4(i_hex03_readback),

        .i_in5(i_hex47_readback),

        .i_in6(i_lcd_readback),

        .i_sel0(i_mem_sel),

        .i_sel1(i_sw_sel),

        .i_sel2(i_ledr_sel),

        .i_sel3(i_ledg_sel),

        .i_sel4(i_hex03_sel),

        .i_sel5(i_hex47_sel),

        .i_sel6(i_lcd_sel),

        .o_y (raw_ld_data)

    );


endmodule



//######################################################################

// MODULE CON 6: lsu_store_preprocessor (Tạo Byte Mask cho D$)

//######################################################################

module lsu_store_preprocessor (

    input  logic [31:0] i_st_data,

    input  logic       i_lsu_wren,

    input  logic [2:0] i_mem_funct3,

    input  logic [1:0] i_addr_bits,

    output logic [3:0] o_mem_bmask,

    output logic [31:0] o_wdata

);

    // Tín hiệu nội bộ

    logic f2, f1, f0, a1, a0,is_sb,i_sh,i_sw;

    logic [3:0] bmask_temp; 

    logic [7:0]  src_byte; // byte thấp của data store

    logic [15:0] src_half; // halfword thấp của data store


    // Gán các tín hiệu phụ để dễ thao tác

    assign f2 = i_mem_funct3[2]; assign f1 = i_mem_funct3[1]; assign f0 = i_mem_funct3[0];

    assign a1 = i_addr_bits[1];  assign a0 = i_addr_bits[0];

    assign is_sb = (~f2) & (~f1) & (~f0); // 000

    assign is_sh = (~f2) & (~f1) & ( f0); // 001

    assign is_sw = (~f2) & ( f1) & (~f0); // 010

    assign src_byte  = i_st_data[7:0];

    assign src_half = i_st_data[15:0];

	 
    // bit_mask gửi cho memory , bit i bật thì byte i của data sẽ được ghi vào bytei của ô nhớ 

    assign bmask_temp[0] = ( ( is_sb & ((~a1) & (~a0)) ) | ( is_sh & (~a1) ) | ( is_sw ) );

    assign bmask_temp[1] = ( ( is_sb & ((~a1) & ( a0)) ) | ( is_sh & (~a1) ) | ( is_sw ) );

    assign bmask_temp[2] = ( ( is_sb & (( a1) & (~a0)) ) | ( is_sh & ( a1) ) | ( is_sw ) );

    assign bmask_temp[3] = ( ( is_sb & (( a1) & ( a0)) ) | ( is_sh & ( a1) ) | ( is_sw ) );

    assign o_mem_bmask = bmask_temp & {4{i_lsu_wren}};

 
 // mã hoá các data cần đưa vào mux
    logic [31:0] i_in [6:0];

    assign i_in[0]  = i_st_data; //sw

    assign i_in[1] = {24'h0, src_byte};//sb0

    assign i_in[2] = {16'h0, src_byte, 8'h0};//sb1

    assign i_in[3] = {8'h0,  src_byte, 16'h0};//sb2

    assign i_in[4] = {       src_byte, 24'h0};//sb3

    assign i_in[5] = {16'h0, src_half};//sh0

    assign i_in[6] = {       src_half, 16'h0};//sh1

	 
	//Decoder 5 sang 7 cho các bit select one-hot nhưng làm trực tiếp 
    logic [7:0] i_sel;

    assign i_sel[0] = is_sw;// không quan tâm 2bit địa chỉ cuối 

    assign i_sel[1] = is_sb & (~a1) & (~a0);// 2bit cuối địa chỉ 00 ghi byte 0

    assign i_sel[2] = is_sb & (~a1) & a0;//2bit cuối địa chỉ 01 ghi byte 1

    assign i_sel[3] = is_sb & (a1) & (~a0);//2bit cuối địa chỉ là 10 ghi byte2

    assign i_sel[4] = is_sb & a1 & a0;// 11 ghi byte 3

    assign i_sel[5] = is_sh & (~a1); //không quan tâm bit cuối nếu bit1=0 thì ghi half-w dưới

    assign i_sel[6] = is_sh & a1;


	 //Mux chọn data sau đã được xử lí cho các câu lệnh sw,sb,sh   
	mux7to1_32bit u_mux_store (

        .i_in0(i_in[0]),

        .i_in1(i_in[1]),

        .i_in2(i_in[2]),

        .i_in3(i_in[3]),

        .i_in4(i_in[4]),

        .i_in5(i_in[5]),

        .i_in6(i_in[6]),

        .i_sel0(i_sel[0]),

        .i_sel1(i_sel[1]),

        .i_sel2(i_sel[2]),

        .i_sel3(i_sel[3]),

        .i_sel4(i_sel[4]),

        .i_sel5(i_sel[5]),

        .i_sel6(i_sel[6]),

        .o_y (o_wdata)

    );



endmodule