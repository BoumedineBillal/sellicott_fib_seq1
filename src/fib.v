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
    o_fib,

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

assign o_busy = (iteration != RESET);
assign o_fib  = current;



always @(posedge i_clk) begin
    if (i_reset) begin
        iteration <= RESET;
        prev      <= 1;
        current   <= 0;
        fifo_ptr  <= 0; //## Reset FIFO pointer
        // Clear FIFO memory
        integer i;
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo[i] <= 0;
        end
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
    end
end

endmodule
