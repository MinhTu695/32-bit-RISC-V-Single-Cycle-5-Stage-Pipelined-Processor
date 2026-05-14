module branch_unit (
    // Input: Lệnh ở tầng EX (để lấy Opcode và Funct3)
    input  logic [31:0] instr_EX,

    // Input: Kết quả từ BRC (đã xử lý signed/unsigned bên trong BRC)
    input  logic        br_eq,      // Kết quả so sánh Bằng (Equal)
    input  logic        br_lt,      // Kết quả so sánh Nhỏ hơn (Less Than)

    // Output: Tín hiệu chọn Mux PC
    output logic        pc_sel      // 1 = Chọn PC Target (Nhảy), 0 = Chọn PC+4
);

    // --- 1. DECODE INSTRUCTION ---
    wire [6:0] opcode = instr_EX[6:0];
    wire [2:0] funct3 = instr_EX[14:12];

    // decode EX kiểm tra phải lệnh ở EX đang là B-type hoặc nhảy hay không
    wire is_branch = (opcode == 7'b1100011); // BEQ, BNE, BLT, BGE, BLTU, BGEU
    wire is_jal    = (opcode == 7'b1101111); // JAL - Luôn nhảy
    wire is_jalr   = (opcode == 7'b1100111); // JALR - Luôn nhảy

    // --- 2. CHECK BRANCH CONDITION (Kiểm tra điều kiện rẽ nhánh) ---
    logic branch_cond_met;

    always_comb begin
        case (funct3)
            3'b000: branch_cond_met = br_eq;          // BEQ: Nhảy nếu Bằng
            3'b001: branch_cond_met = ~br_eq;         // BNE: Nhảy nếu Không Bằng          
            // BLT (Signed) hoặc BLTU (Unsigned)
            // Vì BRC đã nhận i_br_un nên br_lt đầu vào đã là kết quả đúng cho cả 2 trường hợp
            3'b100: branch_cond_met = br_lt;          // BLT
            3'b110: branch_cond_met = br_lt;          // BLTU
            // BGE (Signed) hoặc BGEU (Unsigned)
            // Logic: A >= B tương đương với NOT (A < B)
            3'b101: branch_cond_met = ~br_lt;         // BGE
            3'b111: branch_cond_met = ~br_lt;         // BGEU
            
            default: branch_cond_met = 1'b0;
        endcase
    end

    // --- 3. OUTPUT LOGIC ---
    // Chọn PC mới khi: (Là lệnh Branch VÀ Thỏa điều kiện) HOẶC (Là lệnh Jump)
    assign pc_sel = (is_branch & branch_cond_met) | is_jal | is_jalr;

endmodule