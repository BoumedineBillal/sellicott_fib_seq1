`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 8,         // Address width (8 bits for 256 addresses)
    parameter DATA_WIDTH = 32         // Data width (32 bits)
)(
    input  wire                  clk,       // Clock signal
    input  wire                  rst_n,     // Active low reset signal
    input  wire                  we,        // Write Enable (active high)
    input  wire                  oe,        // Output Enable (active high)
    input  wire [ADDR_WIDTH-1:0] address,   // Address input
    input  wire [DATA_WIDTH-1:0] data_in,   // Data input for write operations
    output reg  [DATA_WIDTH-1:0] data_out   // Data output for read operations
);

    // Instantiate the SRAM macro
    sky130_sram_1kbyte_1rw1r_32x256_8 sram_inst (
        .clk0  (clk),         // Clock for Port 0
        .csb0  (~rst_n),      // Chip select for Port 0 (active low, use reset signal for simplicity)
        .web0  (~we),        // Write Enable for Port 0 (active low, negate write enable)
        .wmask0(4'b1111),    // Write mask for Port 0 (write all bytes, adjust as needed)
        .addr0  (address),    // Address for Port 0
        .din0   (data_in),    // Data input for Port 0
        .dout0  (data_out),   // Data output for Port 0
        .clk1   (clk),        // Clock for Port 1
        .csb1   (1'b1),       // Chip select for Port 1 (not used, active high)
        .addr1   (address),   // Address for Port 1
        .dout1  ()            // Data output for Port 1 (not used)
    );

endmodule
