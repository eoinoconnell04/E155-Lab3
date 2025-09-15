/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: This module stores the most recent keypress, and the key press before that
*/
module store_keypresses (
    input logic divided_clk_keypad, 
    input logic new_key, 
    input logic [15:0] key_pressed_value, 
    output logic [15:0] new_digit, 
    output logic [15:0] old_digit
)

    always_ff @(posedge clk) begin
        if (reset == 0) begin
            new_digit     <= 0;
            old_digit     <= 0;
        end 
        else if (new_key) begin
            old_digit <= new_digit;
            new_digit <= key_pressed_value;
        end 
    end

endmodule