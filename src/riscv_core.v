// Tiny 8-bit RISC-V-inspired Core
// Minimal design to fit Tiny Tapeout constraints

`default_nettype none

module riscv_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [7:0]  instruction,
    output wire [7:0]  result,
    output wire [2:0]  pc_out
);

    // Minimal 8-entry x 8-bit register file
    reg [7:0] registers [7:0];

    // 3-bit program counter (8 instructions max)
    reg [2:0] pc;

    // Instruction decode
    wire [1:0] opcode = instruction[7:6];
    wire [2:0] rd     = instruction[5:3];
    wire [2:0] rs     = instruction[2:0];

    // Simple operations
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_AND = 2'b10;
    localparam OP_OR  = 2'b11;

    // ALU result
    reg [7:0] alu_out;

    // Compute ALU result
    always @(*) begin
        case (opcode)
            OP_ADD:  alu_out = registers[rd] + registers[rs];
            OP_SUB:  alu_out = registers[rd] - registers[rs];
            OP_AND:  alu_out = registers[rd] & registers[rs];
            OP_OR:   alu_out = registers[rd] | registers[rs];
            default: alu_out = 8'd0;
        endcase
    end

    // Execute and update registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 3'd0;
            registers[0] <= 8'd0;
            registers[1] <= 8'd5;   // Initialize r1 = 5
            registers[2] <= 8'd3;   // Initialize r2 = 3
            registers[3] <= 8'd0;
            registers[4] <= 8'd0;
            registers[5] <= 8'd0;
            registers[6] <= 8'd0;
            registers[7] <= 8'd0;
        end else if (enable) begin
            // Write result to destination register
            if (rd != 3'd0) begin  // r0 is read-only zero
                registers[rd] <= alu_out;
            end

            // Increment PC
            pc <= pc + 3'd1;
        end
    end

    assign result = alu_out;
    assign pc_out = pc;

endmodule

`default_nettype wire
