/* fib.v
 * Author: Samuel Ellicott
 * Date: Thu Apr 11 18:43:53 EDT 2024
 * Test of calculating the nth value of the fibbonachi sequence
 */
module fib (
    // global control signals
    i_reset,
    i_clk,

    // control signals
    i_stb,
    o_busy,

    // module inputs/outputs
    i_n,
    o_fib
);
parameter WIDTH = 32;
localparam [WIDTH-1:0] RESET = 0;
localparam [WIDTH-1:0] ONE   = 1;
localparam [WIDTH-1:0] TMP1  = 4;
localparam FIFO_DEPTH = 8; //## Define FIFO depth

// global control signals
input wire i_reset;
input wire i_clk;

// control signals
input  wire i_stb;
output wire o_busy;

// module io
input  wire [WIDTH-1:0] i_n;
output wire [WIDTH-1:0] o_fib;

reg [WIDTH-1:0] iteration;
reg [WIDTH-1:0] prev;
reg [WIDTH-1:0] current;

// FIFO memory to store the last 8 values
reg [WIDTH-1:0] fifo [FIFO_DEPTH-1:0]; //## FIFO memory array
reg [$clog2(FIFO_DEPTH)-1:0] fifo_ptr; //## FIFO pointer

reg fifo_valid; //## Signal to indicate valid FIFO data
reg [WIDTH-1:0] fifo_sum; //## To store the sum of FIFO elements

assign o_busy = (iteration != RESET);
assign o_fib  = current;

always @(posedge i_clk) begin
    if (i_reset) begin
        iteration <= RESET;
        prev      <= 1;
        current   <= 0;
        fifo_ptr  <= 0; //## Reset FIFO pointer
        fifo_valid <= 0; //## Reset FIFO valid signal
        fifo_sum <= 0; //## Reset FIFO sum
        // Clear FIFO memory (implicitly done by initialization)
    end
    else if (!o_busy && i_stb) begin
        iteration <= i_n;
        prev      <= 1;
        current   <= 0;
    end
    else if (o_busy) begin
        iteration <= iteration - ONE;
        current   <= prev * prev + current * current - prev * TMP1 - current * TMP1;
        prev      <= current + TMP1;
        
        // Shift FIFO and add the new value
        fifo[fifo_ptr] <= current; //## Store current value in FIFO
        fifo_ptr <= (fifo_ptr + 1) % FIFO_DEPTH; //## Increment and wrap FIFO pointer

        fifo_valid <= 1; //## Mark FIFO data as valid after update
    end
    else if (fifo_valid) begin
        // Compute the sum of FIFO elements
        // Use a shift register approach instead of a for loop
        integer i;
        fifo_sum <= fifo[0] + fifo[1] + fifo[2] + fifo[3] + fifo[4] + fifo[5] + fifo[6] + fifo[7]; //## FIFO sum computation
        
        // Assign the computed sum to current
        current <= fifo_sum;
        fifo_valid <= 0; //## Clear FIFO valid signal after processing
    end
end

endmodule
