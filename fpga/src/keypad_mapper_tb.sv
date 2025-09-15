/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 15, 2025
Module Function: Testbench to test keypad mapper module for E155 Lab 3.
*/


module keypad_mapper_tb();
    logic clk, reset;
    logic [3:0] keypad_vert, keypad_hori;
    logic [15:0] key_pressed;
    logic [15:0] expected;
    logic [31:0] vectornum, errors;
    logic [23:0] testvectors[10000:0];  // 8 input bits, 16 output bits

    // instantiate device under test
    keypad_mapper dut(keypad_vert, keypad_hori, key_pressed);

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("keypad_mapper_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {keypad_vert, keypad_hori, expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if ({key_pressed} !== expected) begin // check result
                $display("Error: input = %b, %b", keypad_vert, keypad_hori);
                $display("output = %b (%b expected)", key_pressed, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 24'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


