module hazard_detection_unit (

    //Instruction
    input  logic [31:0] instr_ID,
    input  logic [31:0] instr_EX,     
    // Input: Từ Branch Unit
    input  logic        branch_taken,   // chắc chắn có nhảy với B-type
    // Outputs: Control Signals
    output logic        stall_PC,       // 1 = Giữ PC
    output logic        stall_IF_ID,    // 1 = Giữ IF/ID
    output logic        flush_IF_ID,    // 1 = đẩy NOP ra ID
    output logic        flush_ID_EX     // 1 = đẩy NOP ra EX 

);



    // =========================================================================
    // decode instruction tại EX
    // =========================================================================

    wire [6:0] opcode_EX = instr_EX[6:0];
    wire [4:0] rd_EX     = instr_EX[11:7];
    // Phát hiện các loại lệnh quan trọng tại EX
    wire is_load_EX = (opcode_EX == 7'b0000011); // LW, LB...
    // Jump tại EX
    wire is_jal_EX  = (opcode_EX == 7'b1101111); // JAL
    wire is_jalr_EX = (opcode_EX == 7'b1100111); // JALR
  
  // Tín hiệu Jump/Branch thực tế:
    wire pc_redirect;
    assign pc_redirect = branch_taken | is_jal_EX | is_jalr_EX;

    // =========================================================================

    // decode instruction tại ID

    // =========================================================================

    wire [6:0] opcode_ID = instr_ID[6:0];
    wire [4:0] rs1_ID    = instr_ID[19:15];
    wire [4:0] rs2_ID    = instr_ID[24:20];
    wire is_store_ID  = (opcode_ID == 7'b0100011); 
    wire is_branch_ID = (opcode_ID == 7'b1100011); 
    wire is_jalr_ID   = (opcode_ID == 7'b1100111); // JALR dùng rs1
    wire is_op_ID     = (opcode_ID == 7'b0110011); // R-Type
    wire is_op_imm_ID = (opcode_ID == 7'b0010011); // I-Type
    wire is_load_ID   = (opcode_ID == 7'b0000011); 

    // Các lệnh dùng rs1, rs2
    wire uses_rs1_ID = is_op_imm_ID | is_op_ID | is_load_ID | is_store_ID | is_branch_ID | is_jalr_ID;
    wire uses_rs2_ID = is_op_ID | is_store_ID | is_branch_ID;
 

 // Điều kiện Load-Use:
    wire load_use_cond;
    assign load_use_cond = is_load_EX && (rd_EX != 0) &&

                           ( (uses_rs1_ID && (rs1_ID == rd_EX)) | 

                             (uses_rs2_ID && (rs2_ID == rd_EX)) );


    //Tín hiệu phát hiện cần Jump/Branch khi EX gặp lệnh nhảy
    wire pc_redirect_now;
    assign pc_redirect_now = branch_taken | is_jal_EX | is_jalr_EX;
    // 3. LOGIC ĐIỀU KHIỂN OUTPUT
    //Stall PC
   // Giữ PC lại nếu Load-Use, TRỪ KHI đang phải nhảy (pc_redirect)
    assign stall_PC = (load_use_cond & ~pc_redirect_now) ; 
    // STALL IF/ID
    // Chỉ Stall khi Load, Jump cần Flush chứ ko cần giữ stall
    assign stall_IF_ID = load_use_cond & ~pc_redirect_now;
    // 3. Flush ID/EX (Xóa lệnh đang chuẩn bị vào EX)
   // Flush 
    assign flush_IF_ID = pc_redirect_now; 
    // Flush ID/EX: Cái này dùng để biến lệnh ở ID thành NOP khi đưa sang EX
    // không cần stall 2 cycle vì đã chèn NOP vào ID ở chu kỳ trước thì chu kỳ sau vẫn sẽ đưa data NOP đó sang EX
    assign flush_ID_EX = load_use_cond | pc_redirect_now;

endmodule