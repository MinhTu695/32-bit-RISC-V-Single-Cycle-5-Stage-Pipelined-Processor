//######################################################################
// MODULE: imem_pipelined (ASYNC READ MODE - Simulation Optimized)
//######################################################################
module imem_pipelined (
    input  logic        i_clk,    // Giữ lại để không lỗi nối dây, nhưng không dùng
    input  logic        i_reset,  // Giữ lại

    // Địa chỉ (PC[15:2])
    input  logic [13:0] i_addr,

    // Dữ liệu đọc ra (lệnh 32-bit) - Ra ngay lập tức
    output logic [31:0] instr_IF
);

    // Khai báo mảng bộ nhớ
    logic [31:0] mem_array [0:1]; // 64KB

    // Khởi tạo
    initial begin
        $readmemh("isa_4b.hex", mem_array);
    end

    //------------------------------------------------------------------
    // SỬA ĐỔI: Logic Đọc Bất Đồng Bộ (Combinational Read)
    //------------------------------------------------------------------
    // Dùng assign thay vì always_ff. 
    // Instruction thay đổi ngay khi i_addr thay đổi.
    assign instr_IF = mem_array[i_addr];

endmodule