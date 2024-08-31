
`default_nettype none

module tt_um_yourname_sram (
    input  wire [7:0] ui_in,    // Data input (8 bits)
    output wire [7:0] uo_out,   // Data output (8 bits)
    input  wire [7:0] uio_in,   // Address and control signals input (8 bits)
    output wire [7:0] uio_out,  // Address and control signals output (8 bits)
    output wire [7:0] uio_oe,   // Output enable control
    input  wire       ena,      // Enable (always 1)
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset (active low)
);

    // Extract signals
    wire [3:0] address = uio_in[3:0]; // 4-bit address (16 locations)
    wire       we      = uio_in[4];   // Write Enable
    wire       oe      = uio_in[5];   // Output Enable

    sram #(
        .ADDR_WIDTH(4),  // 4-bit address space (16 bytes)
        .DATA_WIDTH(8)   // 8-bit data width
    ) sram_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .we       (we),
        .oe       (oe),
        .address  (address),
        .data_in  (ui_in),
        .data_out (uo_out)
    );

    // Assign output enable control
    assign uio_oe = {6'h0, oe, 1'h0};  // Only bit 5 (for oe) is enabled

    // Unused outputs to zero
    assign uio_out = 8'h00;

endmodule
