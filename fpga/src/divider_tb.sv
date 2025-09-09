/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 3, 2025
Module Function: Testbench to test clock divider, parameterized for a TOGGLE_COUNT = 10;
*/


module divider_tb();
    logic clk, reset;
    logic divided_clk;
    logic expected;
    logic [31:0] vectornum, errors;
    logic testvectors[10000:0];

    // instantiate device under test
    divider #(.TOGGLE_COUNT(10)) dut (.clk(clk), .reset(~reset), .divided_clk(divided_clk));

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("divider_tb.tv", testvectors);
		//$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; expected = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if (divided_clk !== expected) begin // check result
                $display("Error: DUT output = %b", divided_clk);
                $display(" output = %b (%b expected)", divided_clk, expected);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 1'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


