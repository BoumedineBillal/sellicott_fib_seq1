`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 8,         // Address width (8 bits for 256 addresses)
    parameter DATA_WIDTH = 8          // Data width (8 bits to match the input/output width)
)(
    input  wire                  clk,       // Clock signal
    input  wire                  rst_n,     // Active low reset signal
    input  wire                  we,        // Write Enable (active high)
    input  wire                  oe,        // Output Enable (active high)
    input  wire [ADDR_WIDTH-1:0] address,   // Address input
    input  wire [DATA_WIDTH-1:0] data_in,   // Data input for write operations
    output reg  [DATA_WIDTH-1:0] data_out   // Data output for read operations
);

    // Internal signal for data_out to match DATA_WIDTH of 32 in the SRAM macro
    reg [31:0] internal_data_out;

    // Instantiate the SRAM macro
    sky130_sram_1kbyte_1rw1r_32x256_8 sram_inst (
        .clk0  (clk),         // Clock for Port 0
        .csb0  (~rst_n),      // Chip select for Port 0 (active low, use reset signal for simplicity)
        .web0  (~we),         // Write Enable for Port 0 (active low, negate write enable)
        .wmask0(4'b0001),     // Write mask for Port 0 (only write the first byte)
        .addr0 (address),     // Address for Port 0
        .din0  ({24'b0, data_in}), // Data input for Port 0 (extend data_in to 32 bits)
        .dout0 (internal_data_out), // Data output for Port 0 (32 bits)
        .clk1  (clk),         // Clock for Port 1
        .csb1  (1'b1),        // Chip select for Port 1 (not used, active high)
        .addr1 (address),     // Address for Port 1
        .dout1 ()             // Data output for Port 1 (not used)
    );

    // Assign only the lower 8 bits of internal_data_out to data_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (oe)
            data_out <= internal_data_out[7:0];
    end

endmodule
