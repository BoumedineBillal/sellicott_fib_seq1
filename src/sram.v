`default_nettype none

module simple_sram #(
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

    // Define the SRAM memory array
    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

    // Memory Read/Write Operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset output to 0 on reset
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (we) begin
            // Write operation
            mem[address] <= data_in;
        end
        
        // Read operation
        if (oe) begin
            data_out <= mem[address];
        end
    end

endmodule
