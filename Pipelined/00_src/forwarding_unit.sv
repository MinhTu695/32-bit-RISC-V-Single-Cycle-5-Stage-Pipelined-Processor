module forwarding_unit (
    input  logic [31:0] instr_EX,
    input  logic [31:0] instr_MEM,
	 input  logic [31:0] instr_WB,
	 output logic [1:0] sel_store_fwd,
    output logic [1:0] sel_mux1, // Select ALU SrcA: 0=rs1, 1=PC, 2=Forward
    output logic [1:0] sel_mux2  // Select ALU SrcB: 0=rs2, 1=Imm, 2=Forward
);

    //decode EX
    wire [6:0] op_EX = instr_EX[6:0];
    wire [4:0] rs1_EX = instr_EX[19:15];
    wire [4:0] rs2_EX = instr_EX[24:20];
    wire is_lui_EX    = (op_EX == 7'b0110111); // LUI
    wire is_auipc_EX  = (op_EX == 7'b0010111); // AUIPC
    wire is_jal_EX    = (op_EX == 7'b1101111); // JAL
    wire is_jalr_EX   = (op_EX == 7'b1100111); // JALR
    wire is_branch_EX = (op_EX == 7'b1100011); // BEQ, BNE...
    wire is_load_EX   = (op_EX == 7'b0000011); // LW, LB...
    wire is_store_EX  = (op_EX == 7'b0100011); // SW, SB...
    wire is_imm_EX    = (op_EX == 7'b0010011); // ADDI, SLTI...
    wire is_op_EX     = (op_EX == 7'b0110011); // ADD, SUB... (R-Type)   
    // Lệnh nào thực sự dùng RS1 vào ALU ở EX stage
    wire uses_rs1;
    assign uses_rs1 = is_jalr_EX | is_branch_EX | is_load_EX | is_store_EX | is_imm_EX | is_op_EX;
    // Lệnh nào thực sự dùng RS2 để vào ALU ở EX stage
    wire uses_rs2_at_alu;
    assign uses_rs2_at_alu = is_branch_EX | is_op_EX;
    // Chỉ AUIPC và JAL dùng PC + Imm , với branch thì có mux riêng ở ngoài để đưa PC vào tính PC_target
    wire use_PC_at_A;
    assign use_PC_at_A = is_auipc_EX | is_jal_EX;
    // MUX B chọn Immediate
    wire use_Imm_at_B;
    assign use_Imm_at_B = is_lui_EX | is_auipc_EX | is_jal_EX | is_jalr_EX | is_load_EX | is_store_EX | is_imm_EX;

 
    //decode MEM
    wire [6:0] op_MEM = instr_MEM[6:0];
    wire [4:0] rd_MEM = instr_MEM[11:7];

    // --- Kiểm tra xem lệnh ở MEM có GHI Register (RegWrite) không? ---
    wire is_branch_MEM = (op_MEM == 7'b1100011); // Branch không ghi
    wire is_store_MEM  = (op_MEM == 7'b0100011); // Store không ghi
    wire is_nop_MEM    = (instr_MEM == 32'b0);   // NOP

    wire reg_write_MEM;
    assign reg_write_MEM = ~(is_branch_MEM | is_store_MEM | is_nop_MEM);
	 
	 // decode WB
	 wire [4:0] rd_WB = instr_WB[11:7];
	 // Kiểm tra xem lệnh ở WB có ghi Register không? (Giống logic MEM)
    wire is_branch_WB = (instr_WB[6:0] == 7'b1100011);
    wire is_store_WB  = (instr_WB[6:0] == 7'b0100011);
    wire is_nop_WB    = (instr_WB == 32'b0) || (instr_WB == 32'h00000013); // Check cả NOP 
  
    wire reg_write_WB = ~(is_branch_WB | is_store_WB | is_nop_WB);

    // =========================================================================
    // 3. LOGIC PHÁT HIỆN HAZARD & ĐIỀU KHIỂN
    // =========================================================================
    
    wire rd_not_zero = |rd_MEM; // Đảm bảo không forward thanh ghi x0

    // bộ compare địa chỉ tích hợp , kiểm tra trùng địa chỉ thanh ghi đích tầng mem với tg nguồn tầng EX
    wire match_rs1 = (rs1_EX == rd_MEM);
    wire match_rs2 = (rs2_EX == rd_MEM);

    // --- Hazard thật sự (Có ghi + Khác x0 + Trùng địa chỉ + CÓ DÙNG THANH GHI ĐÓ) ---
    // Thêm điều kiện `uses_rs...` để tránh False Hazard cho LUI/AUIPC/JAL
    wire hazard_A_MEM = reg_write_MEM & rd_not_zero & match_rs1 & uses_rs1;
    wire hazard_B_MEM = reg_write_MEM & rd_not_zero & match_rs2 & uses_rs2_at_alu;
	 
	 // Điều kiện Hazard WB:
    wire hazard_A_WB = reg_write_WB && (rd_WB != 0) && (rd_WB == rs1_EX) && uses_rs1;
    wire hazard_B_WB = reg_write_WB && (rd_WB != 0) && (rd_WB == rs2_EX) && uses_rs2_at_alu;

    // =========================================================================
    // 4. OUTPUT SELECT SIGNALS (PRIORITY ENCODER)
    // =========================================================================
    
 // --- MUX 1 (Src A) ---ALU 01-PC , 10-alu_MEM , 11-alu_WB ,  
    always_comb begin
        if (use_PC_at_A)       sel_mux1 = 2'b01; // Lấy PC
        else if (hazard_A_MEM) sel_mux1 = 2'b10; // Forward MEM
        else if (hazard_A_WB)  sel_mux1 = 2'b11; // Forward WB [MỚI]
        else                   sel_mux1 = 2'b00; // Rs1 gốc
    end

    // --- MUX 2 (Src B) ---ALU
    always_comb begin
        if (use_Imm_at_B)      sel_mux2 = 2'b01; // Lấy Imm
        else if (hazard_B_MEM) sel_mux2 = 2'b10; // Forward MEM
        else if (hazard_B_WB)  sel_mux2 = 2'b11; // Forward WB [MỚI]
        else                   sel_mux2 = 2'b00; // Rs2 gốc
    end

      //cho ex/mem đi vào lsu
	 always_comb begin
        if (hazard_B_MEM)      sel_store_fwd = 2'b10; // Forward MEM
        else if (hazard_B_WB)  sel_store_fwd = 2'b11; // Forward WB
        else                   sel_store_fwd = 2'b00; // Lấy rs2 gốc
    end


endmodule