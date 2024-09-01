`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 4,         // Address width (4 bits for 16 addresses)
    parameter DATA_WIDTH = 8          // Data width (8 bits)
)(
    input  wire                  clk,       // Clock signal
    input  wire                  rst_n,     // Active low reset signal
    input  wire                  we,        // Write Enable (active high)
    input  wire                  oe,        // Output Enable (active high)
    input  wire [ADDR_WIDTH-1:0] address,   // Address input (4 bits)
    input  wire [DATA_WIDTH-1:0] data_in,   // Data input for write operations (8 bits)
    output reg  [DATA_WIDTH-1:0] data_out   // Data output for read operations (8 bits)
);

    // Internal signals
    reg [DATA_WIDTH-1:0] internal_data_out;

    // Instantiate the SRAM macro with the adjusted address and data widths
    sky130_sram_1kbyte_1rw1r_32x256_8 sram_inst (
        .clk0  (clk),          // Clock for Port 0
        .csb0  (~rst_n),       // Chip select for Port 0 (active low, use reset signal for simplicity)
        .web0  (~we),          // Write Enable for Port 0 (active low, negate write enable)
        .wmask0(4'b0001),      // Write mask for Port 0 (write the first byte only)
        .addr0 ({4'b0000, address}),  // Adjusted address to match the 8-bit address input (4 MSB zeros)
        .din0  ({24'b0, data_in}),    // Adjusted data input (upper 24 bits zeroed out)
        .dout0 (internal_data_out),   // Internal data output (32 bits)
        .clk1  (clk),          // Clock for Port 1
        .csb1  (1'b1),         // Chip select for Port 1 (not used, active high)
        .addr1 ({4'b0000, address}),  // Adjusted address for Port 1 (not used)
        .dout1 ()              // Data output for Port 1 (not used)
    );

    // Output assignment
    always @(posedge clk) begin
        if (oe) begin
            data_out <= internal_data_out[7:0];  // Take only the relevant 8 bits
        end else begin
            data_out <= 8'b0;
        end
    end

endmodule
