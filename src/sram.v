`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 4,         // 4-bit address, supporting 16 memory locations
    parameter DATA_WIDTH = 8          // 8-bit data width
)(
    input  wire                  clk,       // Clock signal
    input  wire                  rst_n,     // Active low reset signal
    input  wire                  we,        // Write Enable signal (active high)
    input  wire                  oe,        // Output Enable signal (active high)
    input  wire [ADDR_WIDTH-1:0] address,   // Address input
    input  wire [DATA_WIDTH-1:0] data_in,   // Data input for write operations
    output reg  [DATA_WIDTH-1:0] data_out   // Data output for read operations
);

    // Define the SRAM memory array
    reg [DATA_WIDTH-1:0] sram_mem [0:(1<<ADDR_WIDTH)-1];  // 16 locations of 8-bit width memory

    // Sequential block for memory write operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all outputs and optionally initialize memory
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we) begin
                // Write operation
                sram_mem[address] <= data_in;
            end
        end
    end

    // Combinational block for memory read operations
    always @(*) begin
        if (oe) begin
            // Read operation
            data_out = sram_mem[address];
        end else begin
            // If output is not enabled, set data_out to zero (or keep previous value)
            data_out = {DATA_WIDTH{1'b0}}; // Alternatively, keep the previous value: data_out = data_out;
        end
    end

endmodule
