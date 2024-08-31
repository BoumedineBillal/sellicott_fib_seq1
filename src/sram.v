`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 4,         // Address width (4 bits for 16 addresses)
    parameter DATA_WIDTH = 8          // Data width (8 bits)
)(
    input  wire                  clk,       // Clock signal
    input  wire                  rst_n,     // Active low reset signal
    input  wire                  we,        // Write Enable (active high)
    input  wire                  oe,        // Output Enable (active high)
    input  wire [ADDR_WIDTH-1:0] address,   // Address input
    input  wire [DATA_WIDTH-1:0] data_in,   // Data input for write operations
    output wire [DATA_WIDTH-1:0] data_out   // Data output for read operations
);

    // Instantiate the SkyWater SKY130 2kb SRAM macro (256 x 8 bits)
    sram_1rw1r_32_256_8_sky130 sram_inst ( //  sky130_sram_2kbyte_1rw1r_8x256_8
        .clk0(clk),                // Clock input
        .csb0(~(we | oe)),         // Chip select, active low (disabled when both we and oe are low)
        .web0(~we),                // Write enable, active low
        .addr0(address),           // Address input
        .din0(data_in),            // Data input
        .dout0(data_out)           // Data output
    );

    // Optional: Handle reset by gating the data_out signal
    // If reset is needed for your design, you can add additional logic here.
    // However, in typical SRAM usage, reset does not affect the stored data.

endmodule
