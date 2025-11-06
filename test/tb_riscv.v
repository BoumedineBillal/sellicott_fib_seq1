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
        #50;
        rst_n = 1;
        #20;

        $display("=== 16-bit RISC-V Core Test ===");
        $display("Loading instructions into memory...");

        // Load a simple program with 16-bit instructions (each byte ≤ 0x3F):
        // Instruction format: [opcode:4][rd:4][rs1:4][rs2/imm:4]

        // Instruction 0: ADDI x1, x0, 5  (opcode=0001, rd=0001, rs1=0000, imm=0101)
        // Binary: 0001_0001_0000_0101 = 0x1105, low=0x05, high=0x11
        load_instruction_16(16'h1105);

        // Instruction 1: ADDI x2, x0, 3  (opcode=0001, rd=0010, rs1=0000, imm=0011)
        // Binary: 0001_0010_0000_0011 = 0x1203, low=0x03, high=0x12
        load_instruction_16(16'h1203);

        // Instruction 2: ADD x3, x1, x2  (opcode=0000, rd=0011, rs1=0001, rs2=0010)
        // Binary: 0000_0011_0001_0010 = 0x0312, low=0x12, high=0x03
        load_instruction_16(16'h0312);

        // Instruction 3: SUB x4, x1, x2  (opcode=0000, rd=0100, rs1=0001, rs2=0001 for SUB)
        // Binary: 0000_0100_0001_0001 = 0x0411, low=0x11, high=0x04
        load_instruction_16(16'h0411);

        // Instruction 4: NOP (0x0000) - will halt
        load_instruction_16(16'h0000);

        $display("Instructions loaded. Starting execution...");

        // Switch to run mode
        ui_in = 8'b00000000;  // mode = 00 (run)
        uio_in = 8'b00000000; // output_sel = 00 (PC[7:0])

        // Run for several cycles
        #400;

        // Check PC output
        $display("PC (low) = 0x%02X", uo_out);

        // Switch to ALU result output
        uio_in = 8'b00000010; // output_sel = 10 (ALU result[7:0])
        #20;
        $display("ALU Result (low byte) = 0x%02X", uo_out);

        uio_in = 8'b00000011; // output_sel = 11 (ALU result[15:8])
        #20;
        $display("ALU Result (high byte) = 0x%02X", uo_out);

        // Check halt flag
        if (uio_out[7]) begin
            $display("✓ Core halted as expected");
        end else begin
            $display("✗ Core did not halt");
        end

        $display("=== Test Complete ===");
        $finish;
    end

    // Task to load a 16-bit instruction
    task load_instruction_16;
        input [15:0] instr;
        begin
            // Load low byte: mode=01 (0x40) + low byte of instruction
            // Since mode bits become part of data, we send the actual byte values
            ui_in = instr[7:0];  // Low byte
            ui_in[7:6] = 2'b01;  // Set mode to 01
            #20;

            // Load high byte: mode=10 (0x80) + high byte of instruction
            ui_in = instr[15:8];  // High byte
            ui_in[7:6] = 2'b10;  // Set mode to 10
            #20;

            $display("Loaded instruction: 0x%04X", instr);
        end
    endtask

endmodule

`default_nettype wire
