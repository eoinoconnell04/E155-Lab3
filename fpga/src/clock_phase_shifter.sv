/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: This module takes a clock and outputs a NUM_BITS bit one hot output that increments the one hot signal each clock cycle.
Parameter: NUM_BITS
Ex: 0001 -> 0010 -> 0100 -> 1000 -> 0001
*/

module clock_phase_shifter #(
    parameter integer NUM_BITS = 4  // width of the one-hot output
)(
    input  logic                clk,
    input  logic                reset,     // active-low synchronous reset
    output logic  [NUM_BITS-1:0] one_hot_output
);

    always @(posedge clk) begin
        if (reset == 0) begin
            one_hot_output <= {{(NUM_BITS-1){1'b0}}, 1'b1}; // start at LSB = 1
        end else begin
            // Rotate left
            one_hot_output <= {one_hot_output[NUM_BITS-2:0], one_hot_output[NUM_BITS-1]};
        end
    end
    
endmodule