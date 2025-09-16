/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 9, 2025
Module Function: This is the top level module for E155 Lab 3. It performs 2 main functions:
1. Controls two seven segment display as a function of two different 4 input dip switches.
2. Controls 5 led lights that display the binary sum of the two hex digits.
*/
module lab3_eo(
	input  logic reset,
    input  logic [3:0] keypad_hori,
    output logic [3:0] keypad_vert,
	output logic [6:0] seg,
	output logic display1, display2
);

	// Initialize internal signals
    logic divided_clk_keypad;
	logic clk, divided_clk_display;
	logic [3:0] display_input;
    logic [3:0] keypad_sync;
    logic [3:0] keypad_vert_shifted;
    logic [15:0] keys_pressed, key_pressed_value, new_digit, old_digit;
    logic new_key;
    logic [3:0] new_digit_hex, old_digit_hex;
	
	// Internal high-speed oscillator (outputs 48 Mhz clk)
	HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    // Initialize clock divider for keypad
    divider #(.TOGGLE_COUNT(1000)) div_keypad (.clk(divided_clk_keypad), .reset(reset), .divided_clk(divided_clk_keypad));

    // Initialize clock divider for seven segment display (Goal frequency ~250 Hz, 48 Mhz / n = 250 Hz, n = 192000).
    divider #(.TOGGLE_COUNT(192000)) div_display (.clk(divided_clk_keypad), .reset(reset), .divided_clk(divided_clk_display));

    // synchronizer to make sure that all keyboard inputs are stable
    synchronizer s1 (divided_clk_keypad, reset, keypad_hori, keypad_sync);

    // syncronizer for clock_phase_shifter to allign with keyboard inputs
    synchronizer s2 (divided_clk_keypad, reset, keypad_vert, keypad_vert_shifted);

    // Initialize keypad reader module
    //keypad k (keypad_sync, key_pressed);

    // Initialize phase shifter to drive 4 keyboard vertical rails
    clock_phase_shifter c (divided_clk_keypad, reset, keypad_vert);

    // Initialize keypad output to key mapping
    keypad_mapper km (keypad_vert_shifted, keypad_sync, keys_pressed);

    // Initialize FSM to control for switch jitter
    // should this return a hex number and an enable or other singal to signify a switch
    jitter_controller #(.CYCLE_WAIT_TIME(4_000_0)) j (divided_clk_keypad, reset, keys_pressed, key_pressed_value, new_key);

    // Register to store last 2 key presses
    store_keypresses s (divided_clk_keypad, reset, new_key, key_pressed_value, new_digit, old_digit);

    // Convert one hot to hex to display them
    onehot_to_hex o1 (new_digit, new_digit_hex);
    onehot_to_hex o2 (old_digit, old_digit_hex);

	// Seven segment display Input Mux (if divided_clk is high, then s1 selected. If divided_clk is low then s2 selected)
	assign display_input = divided_clk_display ? new_digit_hex : old_digit_hex;

	// Choose which seven segment display to power.
	assign display1 = divided_clk_display;
	assign display2 = ~divided_clk_display;

    // Initialize single seven segment display
    display dis (.s(display_input), .seg(seg));

endmodule