/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: Testbench to test clock phase shifter module for E155 Lab 1.
*/


module store_keypresses_tb();
    logic clk, reset;
    logic new_key;
    logic [15:0] key_pressed_value, new_digit, old_digit;
    logic [31:0] expected;
    logic [31:0] vectornum, errors;
    logic [48:0] testvectors[10000:0];  // 17 input bits, 32 output bits

    // instantiate device under test
    store_keypresses dut(clk, ~reset, new_key, key_pressed_value, new_digit, old_digit);


    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("store_keypresses_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {new_key, key_pressed_value, expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if ({new_digit,old_digit} !== expected) begin // check result
                $display("Error: input = %b, %b", new_digit, key_pressed_value);
                $display("output = %b, %b (%b expected)", new_digit, old_digit, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 49'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


