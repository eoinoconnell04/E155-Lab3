/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: Testbench to test clock phase shifter module for E155 Lab 1.
*/


module display_tb();
    logic clk, reset;
    logic [3:0] expected, one_hot_output;
    logic [31:0] vectornum, errors;
    logic [3:0] testvectors[10000:0];  // 4 expected output bits

    // instantiate device under test
    clock_phase_shifter dut(clk, ~reset, one_hot_output);

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("clock_phase_shifter_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if (one_hot_output !== expected) begin // check result
                $display("Error: output = %b (%b expected)", one_hot_output, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 4'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


