/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 12, 2025
Module Function: This module takes the input of the voltages measured on the horizontal rails of the keypad, combines it with the horizontal control signals, and outputs a 16 bit signal that has a 1 for a digit that is currently pressed.
Inputs: 
keypad_hori: 4 bit signal, each bit representing the voltage on the horizontal rails of the 4x4 keypad
keypad_vert: 4 bit signal, with one bit high controlling which vertical rail gets power

Output: 16 bit signal, each bit representing a different hexadeciaml character. Signal is 1 when key is pressed, 0 elsewise. (least signifiact digit is 0, most significat is F)

Note: because of the one cycle syncronizer, I will compare the horizontal signal to the previous vertical signal

Keypad layout:
Column 0 1 2 3
Row 3: 1 2 3 C
Row 2  4 5 6 D
Row 1  7 8 9 E
Row 0  A 0 B F
*/

module display (
    input  logic [3:0] keypad_vert,
    input  logic [3:0] keypad_hori,
    output logic [15:0] key_pressed
);

    logic [3:0] adjusted_vert;

    // Rotate right by 1 bit (circular shift) 0010 -> 0001
    assign adjusted_vert = {keypad_vert[0], keypad_vert[3:1]};


    always_comb begin
        key_pressed = 16'b0;

        // Row 3
        if (adjusted_vert[0] && keypad_hori[3]) key_pressed[0]  = 1; // '1'
        if (adjusted_vert[1] && keypad_hori[3]) key_pressed[1]  = 1; // '2'
        if (adjusted_vert[2] && keypad_hori[3]) key_pressed[2]  = 1; // '3'
        if (adjusted_vert[3] && keypad_hori[3]) key_pressed[3]  = 1; // 'C'

        // Row 2
        if (adjusted_vert[0] && keypad_hori[2]) key_pressed[4]  = 1; // '4'
        if (adjusted_vert[1] && keypad_hori[2]) key_pressed[5]  = 1; // '5'
        if (adjusted_vert[2] && keypad_hori[2]) key_pressed[6]  = 1; // '6'
        if (adjusted_vert[3] && keypad_hori[2]) key_pressed[7]  = 1; // 'D'

        // Row 1
        if (adjusted_vert[0] && keypad_hori[1]) key_pressed[8]  = 1; // '7'
        if (adjusted_vert[1] && keypad_hori[1]) key_pressed[9]  = 1; // '8'
        if (adjusted_vert[2] && keypad_hori[1]) key_pressed[10] = 1; // '9'
        if (adjusted_vert[3] && keypad_hori[1]) key_pressed[11] = 1; // 'E'

        // Row 0
        if (adjusted_vert[0] && keypad_hori[0]) key_pressed[12] = 1; // 'A'
        if (adjusted_vert[1] && keypad_hori[0]) key_pressed[13] = 1; // '0'
        if (adjusted_vert[2] && keypad_hori[0]) key_pressed[14] = 1; // 'B'
        if (adjusted_vert[3] && keypad_hori[0]) key_pressed[15] = 1; // 'F'
    end

endmodule
