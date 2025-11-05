// Tiny Tapeout wrapper for Tiny RISC-V Core
// Simplified 8-bit design to fit area constraints

`default_nettype none

module tt_um_riscv_core (
    input  wire [7:0] ui_in,    // Instruction input
    output wire [7:0] uo_out,   // Result output
    input  wire [7:0] uio_in,   // Not used
    output wire [7:0] uio_out,  // Status output
    output wire [7:0] uio_oe,   // All outputs
    input  wire       ena,      // Enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset (active low)
);

    wire [2:0] pc;
    wire [7:0] result;

    // Set all uio pins as outputs
    assign uio_oe = 8'b11111111;

    // Core instance
    riscv_core core (
        .clk(clk),
        .rst_n(rst_n),
        .enable(ena),
        .instruction(ui_in),
        .result(result),
        .pc_out(pc)
    );

    // Output assignments
    assign uo_out = result;
    assign uio_out = {5'd0, pc};  // PC on lower 3 bits

    // Suppress unused warnings
    wire _unused = &{uio_in, ena, 1'b0};

endmodule

`default_nettype wire
