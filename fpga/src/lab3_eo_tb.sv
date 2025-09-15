/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 15, 2025
Module Function: Testbench to test top level module for E155 Lab 3.
*/

module lab3_eo_tb();
    logic clk, reset;
    logic [3:0] keypad_hori, keypad_vert;
    logic [6:0] seg, seg_ex;
    logic display1, display2, display1_ex, display2_ex;
    logic [31:0] vectornum, errors;
    logic [16:0] testvectors[10000:0];  //  8 bits of input, 9 output (22 total)

    // instantiate device under test
    lab3_eo_testversion dut(clk, ~reset, keypad_hori, keypad_vert, seg, display1, display2);

    // generate clock
    always begin
        clk = 1; #5; clk = 0; #5;
    end

    // at start of test, load vectors and pulse reset
    initial begin
        $readmemb("lab3_eo_tb.tv", testvectors);
		$display("Loaded test vector 0: %b", testvectors[0]);
        vectornum = 0; errors = 0; reset = 1; #22; reset = 0;
    end

    // apply test vectors on rising edge of clk (this will effectively be both edges of divided_clk)
    always @(posedge clk) begin
        $display("%b", testvectors[vectornum]);
		#1; {keypad_hori, seg_ex, display1_ex, display2_ex} = testvectors[vectornum];
    end

    // check results on falling edge of clk
    always @(negedge clk)
        if (~reset) begin // skip during reset
            if ({seg, display1, display2} !== {seg_ex, display1_ex, display2_ex}) begin // check result
                $display("Error: input = %b", keypad_hori);
                $display("Output: seg: %b, dispaly1: %b, display2: %b. (Expected: seg: %b, dispaly1: %b, display2: %b)", seg, display1, display2, seg_ex, display1_ex, display2_ex);
                errors = errors + 1;
            end
            vectornum = vectornum + 1;
            if (testvectors[vectornum] === 17'bx) begin
                $display("%d tests completed with %d errors", vectornum, errors);
                $stop;
            end
        end
endmodule


