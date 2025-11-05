`default_nettype none
`timescale 1ns / 1ps

module tb_riscv();

    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    wire [7:0] uo_out;
    reg [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg ena;

    // Instantiate the design under test
    tt_um_riscv_core dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end

    // Test stimulus
    initial begin
        $dumpfile("tb_riscv.vcd");
        $dumpvars(0, tb_riscv);

        // Initialize signals
        rst_n = 0;
        ena = 1;
        ui_in = 8'd0;
        uio_in = 8'd0;

        // Reset sequence
        #20;
        rst_n = 1;
        #10;

        $display("=== RISC-V Core Test ===");
        $display("Loading instructions into memory...");

        // Load a simple program:
        // x1 = 5      (ADDI x1, x0, 5)
        // x2 = 3      (ADDI x2, x0, 3)
        // x3 = x1 + x2 (ADD x3, x1, x2)
        // x4 = x1 - x2 (SUB x4, x1, x2)

        // Instruction 0: ADDI x1, x0, 5
        // Format: imm[11:0] | rs1 | funct3 | rd | opcode
        // 000000000101 | 00000 | 000 | 00001 | 0010011
        // 0x00500093
        load_instruction(32'h00500093);

        // Instruction 1: ADDI x2, x0, 3
        // 000000000011 | 00000 | 000 | 00010 | 0010011
        // 0x00300113
        load_instruction(32'h00300113);

        // Instruction 2: ADD x3, x1, x2
        // Format: funct7 | rs2 | rs1 | funct3 | rd | opcode
        // 0000000 | 00010 | 00001 | 000 | 00011 | 0110011
        // 0x002081B3
        load_instruction(32'h002081B3);

        // Instruction 3: SUB x4, x1, x2
        // 0100000 | 00010 | 00001 | 000 | 00100 | 0110011
        // 0x40208233
        load_instruction(32'h40208233);

        // Instruction 4: AND x5, x1, x2
        // 0000000 | 00010 | 00001 | 111 | 00101 | 0110011
        // 0x0020F2B3
        load_instruction(32'h0020F2B3);

        // Instruction 5: OR x6, x3, x4
        // 0000000 | 00100 | 00011 | 110 | 00110 | 0110011
        // 0x0041E333
        load_instruction(32'h0041E333);

        // Instruction 6: NOP (ADDI x0, x0, 0) - will halt
        load_instruction(32'h00000013);

        $display("Instructions loaded. Starting execution...");

        // Switch to run mode
        ui_in = 8'b00000000;  // mode = 00 (run)
        uio_in = 8'b00000000; // output_sel = 00 (PC[7:0])

        // Run for several cycles
        #200;

        // Check PC output
        $display("PC = 0x%02X", uo_out);

        // Switch to ALU result output
        uio_in = 8'b00000010; // output_sel = 10 (ALU result[7:0])
        #10;
        $display("ALU Result (low byte) = 0x%02X", uo_out);

        uio_in = 8'b00000011; // output_sel = 11 (ALU result[15:8])
        #10;
        $display("ALU Result (high byte) = 0x%02X", uo_out);

        $display("=== Test Complete ===");
        $finish;
    end

    // Task to load a 32-bit instruction
    task load_instruction;
        input [31:0] instr;
        begin
            // Load byte 0 (LSB)
            ui_in = {2'b01, instr[5:0]};  // mode=01, data=instr[5:0]
            #10;

            // Load byte 1
            ui_in = {2'b10, instr[13:8]};  // mode=10, data=instr[13:8]
            #10;

            // Load byte 2
            ui_in = {2'b11, instr[21:16]};  // mode=11, data=instr[21:16]
            #10;

            // Load byte 3 and write
            ui_in = {2'b11, instr[29:24]};  // mode=11, data=instr[29:24]
            #10;

            $display("Loaded instruction: 0x%08X", instr);
        end
    endtask

endmodule

`default_nettype wire
