// Simple 32-bit RISC-V Core (RV32I subset)
// Single-cycle implementation with minimal instruction memory

`default_nettype none

module riscv_core #(
    parameter IMEM_SIZE = 64  // Number of 32-bit instruction words
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,

    // Instruction memory interface
    input  wire [31:0] imem_data_in,
    input  wire        imem_we,
    input  wire [7:0]  imem_addr,

    // Data output (for debugging/monitoring)
    output wire [31:0] pc_out,
    output wire [31:0] alu_result_out,
    output wire [4:0]  rd_addr_out,
    output wire        halted
);

    // Program counter
    reg [31:0] pc;
    reg        halt_flag;

    // Instruction memory
    reg [31:0] imem [0:IMEM_SIZE-1];
    wire [31:0] instruction;

    // Instruction decode
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    // Control signals
    reg [3:0]  alu_op;
    reg        reg_we;
    reg        alu_src;      // 0: rs2, 1: immediate
    reg        pc_src;       // 0: pc+4, 1: branch/jump target
    reg [1:0]  wb_sel;       // Write-back select: 00=ALU, 01=PC+4, 10=imm

    // Datapath signals
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] rd_data;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_target;

    // Fetch instruction from memory
    assign instruction = imem[pc[7:2]];  // Word-aligned access

    // Instruction decode
    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    // Immediate generation
    assign imm_i = {{20{instruction[31]}}, instruction[31:20]};
    assign imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    assign imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign imm_u = {instruction[31:12], 12'b0};
    assign imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    // Register file
    riscv_regfile regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rd_data),
        .rd_we(reg_we && !halt_flag),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ALU operand selection
    assign alu_operand_b = alu_src ? imm_i : rs2_data;

    // ALU
    riscv_alu alu (
        .operand_a(rs1_data),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Write-back data selection
    assign rd_data = (wb_sel == 2'b00) ? alu_result :
                     (wb_sel == 2'b01) ? pc_plus_4 :
                     (wb_sel == 2'b10) ? imm_u : 32'd0;

    // PC calculation
    assign pc_plus_4 = pc + 32'd4;
    assign pc_target = pc + imm_b;  // For branches

    // Control logic
    always @(*) begin
        // Default control signals
        alu_op = 4'b0000;
        reg_we = 1'b0;
        alu_src = 1'b0;
        pc_src = 1'b0;
        wb_sel = 2'b00;

        case (opcode)
            // R-type instructions (ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA)
            7'b0110011: begin
                reg_we = 1'b1;
                alu_src = 1'b0;
                wb_sel = 2'b00;
                case (funct3)
                    3'b000: alu_op = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: alu_op = 4'b0010; // AND
                    3'b110: alu_op = 4'b0011; // OR
                    3'b100: alu_op = 4'b0100; // XOR
                    3'b010: alu_op = 4'b0101; // SLT
                    3'b011: alu_op = 4'b0110; // SLTU
                    3'b001: alu_op = 4'b0111; // SLL
                    3'b101: alu_op = (funct7[5]) ? 4'b1001 : 4'b1000; // SRA : SRL
                    default: alu_op = 4'b0000;
                endcase
            end

            // I-type instructions (ADDI, ANDI, ORI, XORI, SLTI, SLTIU)
            7'b0010011: begin
                reg_we = 1'b1;
                alu_src = 1'b1;
                wb_sel = 2'b00;
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b111: alu_op = 4'b0010; // ANDI
                    3'b110: alu_op = 4'b0011; // ORI
                    3'b100: alu_op = 4'b0100; // XORI
                    3'b010: alu_op = 4'b0101; // SLTI
                    3'b011: alu_op = 4'b0110; // SLTIU
                    default: alu_op = 4'b0000;
                endcase
            end

            // LUI (Load Upper Immediate)
            7'b0110111: begin
                reg_we = 1'b1;
                wb_sel = 2'b10;
            end

            // AUIPC (Add Upper Immediate to PC)
            7'b0010111: begin
                reg_we = 1'b1;
                wb_sel = 2'b00;
                alu_src = 1'b1;
            end

            // JAL (Jump and Link)
            7'b1101111: begin
                reg_we = 1'b1;
                wb_sel = 2'b01;
                pc_src = 1'b1;
            end

            // BEQ, BNE (Branch instructions - simplified)
            7'b1100011: begin
                case (funct3)
                    3'b000: pc_src = (rs1_data == rs2_data);      // BEQ
                    3'b001: pc_src = (rs1_data != rs2_data);      // BNE
                    3'b100: pc_src = ($signed(rs1_data) < $signed(rs2_data));  // BLT
                    3'b101: pc_src = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
                    default: pc_src = 1'b0;
                endcase
            end

            default: begin
                // NOP or unsupported instruction
                reg_we = 1'b0;
            end
        endcase
    end

    // PC update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
            halt_flag <= 1'b0;
        end else if (enable && !halt_flag) begin
            if (pc_src) begin
                if (opcode == 7'b1101111) // JAL
                    pc <= pc + imm_j;
                else  // Branch
                    pc <= pc_target;
            end else begin
                pc <= pc_plus_4;
            end

            // Halt on infinite loop or end of memory
            if (pc >= (IMEM_SIZE * 4) || instruction == 32'h00000013) begin
                halt_flag <= 1'b1;
            end
        end
    end

    // Instruction memory write
    always @(posedge clk) begin
        if (imem_we && imem_addr < IMEM_SIZE) begin
            imem[imem_addr] <= imem_data_in;
        end
    end

    // Debug outputs
    assign pc_out = pc;
    assign alu_result_out = alu_result;
    assign rd_addr_out = rd;
    assign halted = halt_flag;

endmodule

`default_nettype wire
