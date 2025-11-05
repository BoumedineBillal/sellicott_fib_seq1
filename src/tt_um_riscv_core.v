// Tiny Tapeout wrapper for Simple RISC-V Core
// Maps limited I/O pins to RISC-V core interface

`default_nettype none

module tt_um_riscv_core (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Enable - goes high when design is selected
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset (active low)
);

    // Internal signals
    wire [31:0] pc_out;
    wire [31:0] alu_result_out;
    wire [4:0]  rd_addr_out;
    wire        halted;

    // Instruction memory interface
    reg  [31:0] imem_data_in;
    reg         imem_we;
    reg  [7:0]  imem_addr;
    reg  [1:0]  imem_load_state;
    reg  [7:0]  imem_byte_count;

    // Mode selection
    // ui_in[7:6]: Mode - 00: Run, 01: Load instruction (byte 0), 10: Load (byte 1), 11: Load (byte 2-3)
    // ui_in[5:0]: Address bits or data
    wire [1:0] mode;
    assign mode = ui_in[7:6];

    // Output selection
    // uio_in[1:0]: Output select
    // 00: PC[7:0], 01: PC[15:8], 10: ALU result[7:0], 11: ALU result[15:8]
    wire [1:0] output_sel;
    assign output_sel = uio_in[1:0];

    // Set all uio pins as outputs
    assign uio_oe = 8'b11111111;

    // Instruction loading state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            imem_data_in <= 32'd0;
            imem_we <= 1'b0;
            imem_addr <= 8'd0;
            imem_load_state <= 2'd0;
            imem_byte_count <= 8'd0;
        end else if (mode != 2'b00) begin
            // Instruction loading mode
            case (mode)
                2'b01: begin  // Load byte 0 (LSB)
                    imem_data_in[7:0] <= ui_in[5:0];
                    imem_load_state <= 2'd1;
                    imem_we <= 1'b0;
                end
                2'b10: begin  // Load byte 1
                    imem_data_in[15:8] <= ui_in[5:0];
                    imem_load_state <= 2'd2;
                    imem_we <= 1'b0;
                end
                2'b11: begin  // Load bytes 2-3 and write
                    if (imem_load_state == 2'd2) begin
                        imem_data_in[23:16] <= ui_in[5:0];
                        imem_load_state <= 2'd3;
                        imem_we <= 1'b0;
                    end else if (imem_load_state == 2'd3) begin
                        imem_data_in[31:24] <= ui_in[5:0];
                        imem_addr <= imem_byte_count;
                        imem_we <= 1'b1;
                        imem_load_state <= 2'd0;
                        imem_byte_count <= imem_byte_count + 1;
                    end
                end
            endcase
        end else begin
            imem_we <= 1'b0;
        end
    end

    // RISC-V Core instance
    riscv_core #(
        .IMEM_SIZE(64)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .enable(ena && mode == 2'b00),  // Only run in mode 00
        .imem_data_in(imem_data_in),
        .imem_we(imem_we),
        .imem_addr(imem_addr),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .rd_addr_out(rd_addr_out),
        .halted(halted)
    );

    // Output multiplexing
    // uo_out: Main outputs
    assign uo_out = (output_sel == 2'b00) ? pc_out[7:0] :
                    (output_sel == 2'b01) ? pc_out[15:8] :
                    (output_sel == 2'b10) ? alu_result_out[7:0] :
                                            alu_result_out[15:8];

    // uio_out: Additional outputs
    assign uio_out = {halted, rd_addr_out, output_sel};

    // Suppress unused signal warnings
    wire _unused = &{ena, 1'b0};

endmodule

`default_nettype wire
