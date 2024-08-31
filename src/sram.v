`default_nettype none

module sram #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  we,      // Write Enable
    input  wire                  oe,      // Output Enable
    input  wire [ADDR_WIDTH-1:0] address, // Address input
    input  wire [DATA_WIDTH-1:0] data_in, // Data input
    output reg  [DATA_WIDTH-1:0] data_out // Data output
);

    // Define the SRAM memory array
    reg [DATA_WIDTH-1:0] sram_mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Optional: Initialize memory or do something on reset
            data_out <= 0;
        end else if (we) begin
            // Write operation
            sram_mem[address] <= data_in;
        end else if (oe) begin
            // Read operation
            data_out <= sram_mem[address];
        end
    end

endmodule

