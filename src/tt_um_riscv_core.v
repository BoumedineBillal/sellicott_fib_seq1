// Tiny Tapeout wrapper for 16-bit RISC-V Core (2x2 tile)

`default_nettype none

module tt_um_riscv_core (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset (active low)
);

    // Internal signals
    wire [15:0] pc_out;
    wire [15:0] alu_result_out;
    wire        halted;

    // Instruction memory interface
    reg  [15:0] imem_data_in;
    reg         imem_we;
    reg  [4:0]  imem_addr;
    reg  [1:0]  load_state;

    // Mode: ui_in[7:6], Data: ui_in[5:0] or full ui_in[7:0]
    // 00: Run mode
    // 01: Load low byte
    // 10: Load high byte and write
    wire [1:0] mode = ui_in[7:6];
    wire [1:0] output_sel = uio_in[1:0];
    wire [7:0] data_byte = ui_in;  // Use full byte for loading

    // Set uio as outputs
    assign uio_oe = 8'b11111111;

    // Instruction loading
    // Strategy: interpret full ui_in as 8-bit data (mode bits become part of data)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            imem_data_in <= 16'd0;
            imem_we <= 1'b0;
            imem_addr <= 5'd0;
            load_state <= 2'd0;
        end else begin
            // Detect mode from pattern matching
            if (ui_in[7:6] == 2'b01) begin  // Load low byte - strip mode bits, pad with 00
                imem_data_in[7:0] <= {2'b00, ui_in[5:0]};  // Only 6 bits of data
                load_state <= 2'd1;
                imem_we <= 1'b0;
            end else if (ui_in[7:6] == 2'b10 && load_state == 2'd1) begin  // Load high byte and write
                imem_data_in[15:8] <= {2'b00, ui_in[5:0]};  // Only 6 bits of data
                imem_we <= 1'b1;
                load_state <= 2'd0;
                imem_addr <= imem_addr + 1;  // Increment address immediately after write
            end else begin
                imem_we <= 1'b0;
            end
        end
    end

    // Core instance
    riscv_core #(
        .IMEM_SIZE(32)
    ) core (
        .clk(clk),
        .rst_n(rst_n),
        .enable(ena && mode == 2'b00),
        .imem_data_in(imem_data_in),
        .imem_we(imem_we),
        .imem_addr(imem_addr),
        .pc_out(pc_out),
        .alu_result_out(alu_result_out),
        .halted(halted)
    );

    // Output multiplexing
    assign uo_out = (output_sel == 2'b00) ? pc_out[7:0] :
                    (output_sel == 2'b01) ? pc_out[15:8] :
                    (output_sel == 2'b10) ? alu_result_out[7:0] :
                                            alu_result_out[15:8];

    assign uio_out = {halted, 5'd0, output_sel};

    // Suppress unused warnings
    wire _unused = &{ena, 1'b0};

endmodule

`default_nettype wire
