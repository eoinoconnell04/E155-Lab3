/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: Testbench to test jitter_controller module for E155 Lab 3.
*/


module synchronizer_tb();
    logic clk, reset;
    logic [15:0] keys_pressed, key_pressed_value;
    logic [16:0] expected;
    logic [31:0] vectornum, errors;
    logic [32:0] testvectors[10000:0];  // 16 input bits, 17 expected output bits

    // instantiate device under test
    jitter_controller #(.CYCLE_WAIT_TIME(4)) dut(clk, ~reset, keys_pressed, key_pressed_value, new_key);

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("jitter_controller_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {keys_pressed, expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if ({key_pressed_value, new_key} !== expected) begin // check result
                $display("Error: output = %b, %b (%b expected)", key_pressed_value, new_key, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] == 33'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


