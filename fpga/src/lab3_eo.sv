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
	input  logic [3:0] s1,
	input  logic [3:0] s2,
    input  logic [3:0] keypad_hori,
    output logic [3:0] keypad_vert,
	output logic [6:0] seg,
	output logic display1, display2,
	output logic [4:0] led
);

	// Initialize internal signals
	logic clk, divided_clk;
	logic [3:0] display_input;
    logic [3:0] keypad_sync;
    logic [15:0] keys_pressed;
	
	// Internal high-speed oscillator (outputs 48 Mhz clk)
	HSOSC hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    // Initialize clock divider (Goal frequency ~250 Hz, 48 Mhz / n = 250 Hz, n = 192000).
    divider #(.TOGGLE_COUNT(192000)) div (.clk(clk), .reset(reset), .divided_clk(divided_clk));

    // Synchronizer to make sure that all keyboard inputs are stable
    synchronizer s (divided_clk, keypad_hori, keypad_sync);

    // Initialize keypad reader module
    keypad k (keypad_sync, key_pressed);

    // Initialize phase shifter to drive 4 keyboard vertical rails
    clock_phase_shifter c (divided_clk, keypad_vert);

    // Initialize keypad output to key mapping
    keypad_mapper km (keypad_vert, keypad_hori, keys_pressed);

    // Initialize FSM to control for switch jitter
    // should this return a hex number and an enable or other singal to signify a switch
    jitter_controller j (divided_clk, keypad_sync, key_pressed_value, new_key);

	// Seven segment display Input Mux (if divided_clk is high, then s1 selected. If divided_clk is low then s2 selected)
	assign display_input = divided_clk ? s1 : s2;

	// Choose which seven segment display to power.
	assign display1 = divided_clk;
	assign display2 = ~divided_clk;

    // Initialize single seven segment display
    display dis (.s(display_input), .seg(seg));

endmodule