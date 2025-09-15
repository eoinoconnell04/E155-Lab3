/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 14, 2025
Module Function: Testbench to test synchronizer module for E155 Lab 3.
*/


module synchronizer_tb();
    logic clk, reset;
    logic [3:0] expected, sync_output, async_input;
    logic [31:0] vectornum, errors;
    logic [7:0] testvectors[10000:0];  // 4 input bits, 4 expected output bits

    // instantiate device under test
    synchronizer dut(clk, ~reset, async_input, sync_output);

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("synchronizer_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {async_input, expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if (sync_output !== expected) begin // check result
                $display("Error: output = %b (%b expected)", sync_output, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 8'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


