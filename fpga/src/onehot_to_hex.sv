/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 15, 2025
Module Function: Converts 16 bit one hot value to 4 bit hex
*/

module onehot_to_hex (
    input  logic [15:0] one_hot,
    output logic [3:0]  hex_value
);

    always_comb begin
        case (one_hot)
            16'b0000_0000_0000_0001: hex_value = 4'h0;
            16'b0000_0000_0000_0010: hex_value = 4'h1;
            16'b0000_0000_0000_0100: hex_value = 4'h2;
            16'b0000_0000_0000_1000: hex_value = 4'h3;
            16'b0000_0000_0001_0000: hex_value = 4'h4;
            16'b0000_0000_0010_0000: hex_value = 4'h5;
            16'b0000_0000_0100_0000: hex_value = 4'h6;
            16'b0000_0000_1000_0000: hex_value = 4'h7;
            16'b0000_0001_0000_0000: hex_value = 4'h8;
            16'b0000_0010_0000_0000: hex_value = 4'h9;
            16'b0000_0100_0000_0000: hex_value = 4'hA;
            16'b0000_1000_0000_0000: hex_value = 4'hB;
            16'b0001_0000_0000_0000: hex_value = 4'hC;
            16'b0010_0000_0000_0000: hex_value = 4'hD;
            16'b0100_0000_0000_0000: hex_value = 4'hE;
            16'b1000_0000_0000_0000: hex_value = 4'hF;
            default:                hex_value = 4'h0; 
        endcase
    end

endmodule
