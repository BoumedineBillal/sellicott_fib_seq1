// 16-bit RISC-V Core for Tiny Tapeout (2x2 tile)
// Balanced design with 16 registers, reasonable instruction set

`default_nettype none

module riscv_core #(
    parameter IMEM_SIZE = 32  // 32 x 16-bit instruction words
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,

    // Instruction memory interface (for loading programs)
    input  wire [15:0] imem_data_in,
    input  wire        imem_we,
    input  wire [4:0]  imem_addr,

    // Outputs
    output wire [15:0] pc_out,
    output wire [15:0] alu_result_out,
    output wire        halted
);

    // Program counter (16-bit, byte-addressed)
    reg [15:0] pc;
    reg        halt_flag;
    integer i;  // Loop variable for initialization

    // Instruction memory (32 x 16-bit)
    reg [15:0] imem [0:IMEM_SIZE-1];
    wire [15:0] instruction;

    // Instruction decode (16-bit compressed format)
    wire [3:0] opcode;
    wire [3:0] rd, rs1, rs2;
    wire [3:0] imm4;
    wire [7:0] imm8;

    assign opcode = instruction[15:12];
    assign rd     = instruction[11:8];
    assign rs1    = instruction[7:4];
    assign rs2    = instruction[3:0];
    assign imm4   = instruction[3:0];
    assign imm8   = instruction[7:0];

    // Sign-extended immediates
    wire [15:0] imm_i = {{12{imm4[3]}}, imm4};
    wire [15:0] imm_u = {imm8, 8'd0};

    // Control signals
    reg [2:0]  alu_op;
    reg        reg_we;
    reg        alu_src;      // 0: rs2, 1: immediate
    reg        pc_src;       // 0: pc+2, 1: branch
    reg [1:0]  wb_sel;       // Write-back: 00=ALU, 01=PC+2, 10=imm_u

    // Register file (16 x 16-bit)
    reg [15:0] registers [15:0];
    wire [15:0] rs1_data = (rs1 == 4'd0) ? 16'd0 : registers[rs1];
    wire [15:0] rs2_data = (rs2 == 4'd0) ? 16'd0 : registers[rs2];

    // ALU
    wire [15:0] alu_operand_b = alu_src ? imm_i : rs2_data;
    reg [15:0] alu_result;

    localparam ALU_ADD  = 3'b000;
    localparam ALU_SUB  = 3'b001;
    localparam ALU_AND  = 3'b010;
    localparam ALU_OR   = 3'b011;
    localparam ALU_XOR  = 3'b100;
    localparam ALU_SLL  = 3'b101;

    always @(*) begin
        case (alu_op)
            ALU_ADD:  alu_result = rs1_data + alu_operand_b;
            ALU_SUB:  alu_result = rs1_data - alu_operand_b;
            ALU_AND:  alu_result = rs1_data & alu_operand_b;
            ALU_OR:   alu_result = rs1_data | alu_operand_b;
            ALU_XOR:  alu_result = rs1_data ^ alu_operand_b;
            ALU_SLL:  alu_result = rs1_data << alu_operand_b[3:0];
            default:  alu_result = 16'd0;
        endcase
    end

    // Write-back data
    wire [15:0] rd_data = (wb_sel == 2'b00) ? alu_result :
                          (wb_sel == 2'b01) ? (pc + 16'd2) :
                          (wb_sel == 2'b10) ? imm_u : 16'd0;

    // PC calculations
    wire [15:0] pc_plus_2 = pc + 16'd2;
    wire [15:0] pc_branch = pc + {imm_i[14:0], 1'b0};

    // Control logic
    always @(*) begin
        // Defaults
        alu_op = ALU_ADD;
        reg_we = 1'b0;
        alu_src = 1'b0;
        pc_src = 1'b0;
        wb_sel = 2'b00;

        case (opcode)
            // R-type: ADD, SUB, AND, OR, XOR, SLL
            4'b0000: begin
                reg_we = 1'b1;
                alu_src = 1'b0;
                case (rs2)
                    4'b0000: alu_op = ALU_ADD;
                    4'b0001: alu_op = ALU_SUB;
                    4'b0010: alu_op = ALU_AND;
                    4'b0011: alu_op = ALU_OR;
                    4'b0100: alu_op = ALU_XOR;
                    4'b0101: alu_op = ALU_SLL;
                    default: alu_op = ALU_ADD;
                endcase
            end

            // I-type immediate ops
            4'b0001: begin  // ADDI
                reg_we = 1'b1;
                alu_src = 1'b1;
                alu_op = ALU_ADD;
            end

            // LUI (Load Upper Immediate)
            4'b0010: begin
                reg_we = 1'b1;
                wb_sel = 2'b10;
            end

            // BEQ, BNE
            4'b0011: begin
                alu_op = ALU_SUB;
                pc_src = (rs1_data == rs2_data);  // BEQ
            end

            4'b0100: begin
                alu_op = ALU_SUB;
                pc_src = (rs1_data != rs2_data);  // BNE
            end

            // JAL (Jump and Link)
            4'b0101: begin
                reg_we = 1'b1;
                wb_sel = 2'b01;  // Write PC+2 to rd
                pc_src = 1'b1;
            end

            default: begin
                reg_we = 1'b0;
            end
        endcase
    end

    // Fetch instruction
    assign instruction = imem[pc[5:1]];  // Word-aligned

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'd0;
            halt_flag <= 1'b0;
            // Initialize registers
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 16'd0;
            end
        end else if (enable && !halt_flag) begin
            // Register write-back
            if (reg_we && rd != 4'd0) begin
                registers[rd] <= rd_data;
            end

            // PC update
            if (pc_src) begin
                pc <= pc_branch;
            end else begin
                pc <= pc_plus_2;
            end

            // Halt check
            if (pc >= (IMEM_SIZE * 2) || instruction == 16'h0000) begin
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

    // Outputs
    assign pc_out = pc;
    assign alu_result_out = alu_result;
    assign halted = halt_flag;

endmodule

`default_nettype wire
