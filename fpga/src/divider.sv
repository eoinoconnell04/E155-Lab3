/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Aug. 30, 2025
Module Function: This module is a parameterized clock divider which takes in a clock and divides it by some multiple.
Parameters: TOGGLE_COUNT: specifies the number of cycles before reset
Note: The TOGGLE_COUNT is the amount of cycles spent on BOTH the on and off state. That means the frequency will be divided by double the TOGGLE_COUNT.
*/
module divider
    #(parameter TOGGLE_COUNT=64)

(   input logic clk, reset,
    output logic divided_clk
);

    // derive counter width automatically
    localparam int COUNTER_WIDTH = $clog2(TOGGLE_COUNT);

    // counter bit width is automatically calculated based on the parameter TOGGLE_COUNT
    logic [COUNTER_WIDTH-1:0] counter;

    // Clock Divider
    always_ff @(posedge clk) begin
        if (reset == 0) begin
            counter     <= 0;
            divided_clk <= 0;
        end 
        else if (counter == TOGGLE_COUNT) begin
            divided_clk <= ~divided_clk;
            counter     <= 0;
        end 
        else begin
            counter <= counter + 1;
        end
    end

endmodule