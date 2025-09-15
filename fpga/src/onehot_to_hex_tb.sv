/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 15, 2025
Module Function: Testbench to test one hot decoder module for E155 Lab 3.
*/


module onehot_to_hex_tb();
    logic clk, reset;
    logic [15:0] one_hot;
    logic [3:0] expected, hex_value;
    logic [31:0] vectornum, errors;
    logic [10:0] testvectors[10000:0];  // 16 input bits, 4 output bits

    // instantiate device under test
    onehot_to_hex dut(one_hot, hex_value);


    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("onehot_to_hex_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {one_hot, expected} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if (hex_value !== expected) begin // check result
                $display("Error: input = %b", one_hot);
                $display("output = %b (%b expected)", hex_value, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 4'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


