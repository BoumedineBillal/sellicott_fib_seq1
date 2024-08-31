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
    output reg  [DATA_WIDTH-1:0] data_out   // Data output for read operations
);

    // Define the SRAM memory array
    reg [DATA_WIDTH-1:0] sram_mem [0:(1<<ADDR_WIDTH)-1];  // 16x8-bit memory

    // Internal wire to hold the selected memory value
    reg [DATA_WIDTH-1:0] selected_data;

    // Combinational logic for read operation using a multiplexer
    always @(*) begin
        case (address)
            4'h0: selected_data = sram_mem[0];
            4'h1: selected_data = sram_mem[1];
            4'h2: selected_data = sram_mem[2];
            4'h3: selected_data = sram_mem[3];
            4'h4: selected_data = sram_mem[4];
            4'h5: selected_data = sram_mem[5];
            4'h6: selected_data = sram_mem[6];
            4'h7: selected_data = sram_mem[7];
            4'h8: selected_data = sram_mem[8];
            4'h9: selected_data = sram_mem[9];
            4'hA: selected_data = sram_mem[10];
            4'hB: selected_data = sram_mem[11];
            4'hC: selected_data = sram_mem[12];
            4'hD: selected_data = sram_mem[13];
            4'hE: selected_data = sram_mem[14];
            4'hF: selected_data = sram_mem[15];
            default: selected_data = 8'b00000000; // Default case for unused address
        endcase
    end

    // Sequential block for read and write operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b00000000; // Reset data output to 0
        end else begin
            if (we) begin
                // Write operation
                sram_mem[address] <= data_in;
            end
            if (oe) begin
                // Output the selected data based on the address
                data_out <= selected_data;
            end else begin
                data_out <= 8'b00000000; // Clear output if not enabled
            end
        end
    end

endmodule
