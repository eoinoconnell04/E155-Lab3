//------------------------------------------------------------------------------
// KeypadScanner
//------------------------------------------------------------------------------
// Scans a 4x4 active-low matrix keypad.
// * Drives one column low at a time.
// * Samples rows to detect a single pressed key.
// * Outputs a 4-bit hex code (0–F) following standard layout:
//     Cols-> 0   1   2   3
// Rows
//   0      1   2   3   A
//   1      4   5   6   B
//   2      7   8   9   C
//   3      E   0   F   D
// * key_valid is high while any key is pressed.
//------------------------------------------------------------------------------
module KeypadScanner #(
    parameter integer CLK_DIV = 12_000  // scan strobe = clk/(2*CLK_DIV)
) (
    input  logic        clk,
    input  logic        rst_n,

    // Matrix interface
    output logic [3:0]  col_n,     // active-low column drives
    input  logic [3:0]  row_n,     // active-low row inputs

    // Results
    output logic        key_valid, // 1 while a key is held
    output logic [3:0]  key_code   // 4-bit hex code of current key
);

    //--------------------------------------------------------------------------
    // Clock divider for scan tick
    //--------------------------------------------------------------------------
    logic [$clog2(CLK_DIV)-1:0] div_cnt;
    logic                       scan_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt   <= '0;
            scan_tick <= 1'b0;
        end else begin
            if (div_cnt == CLK_DIV-1) begin
                div_cnt   <= '0;
                scan_tick <= 1'b1;
            end else begin
                div_cnt   <= div_cnt + 1'b1;
                scan_tick <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------------------
    // FSM for column scanning
    //--------------------------------------------------------------------------
    typedef enum logic [1:0] { COL0, COL1, COL2, COL3 } col_state_t;
    col_state_t col_state, col_next;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col_state <= COL0;
        else if (scan_tick)
            col_state <= col_next;
    end

    always_comb begin
        case (col_state)
            COL0: col_next = COL1;
            COL1: col_next = COL2;
            COL2: col_next = COL3;
            default: col_next = COL0;
        endcase
    end

    // Active-low one-hot column outputs
    always_comb begin
        case (col_state)
            COL0: col_n = 4'b1110;
            COL1: col_n = 4'b1101;
            COL2: col_n = 4'b1011;
            COL3: col_n = 4'b0111;
        endcase
    end

    //--------------------------------------------------------------------------
    // Row sampling and key code generation
    //--------------------------------------------------------------------------
    // Register the detected row/col when any key is pressed.
    logic [1:0] row_idx;
    logic [1:0] col_idx;
    logic       key_detect;

    // Decode row (first active-low bit)
    function automatic [1:0] first_low (input logic [3:0] v);
        casez (v)
            4'b0???: first_low = 2'd0;
            4'b10??: first_low = 2'd1;
            4'b110?: first_low = 2'd2;
            4'b1110: first_low = 2'd3;
            default: first_low = 2'd0; // not used when none low
        endcase
    endfunction

    // detect if any row active
    assign key_detect = (row_n != 4'b1111);

    // capture current key indices
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_idx  <= 2'd0;
            col_idx  <= 2'd0;
        end else if (scan_tick) begin
            if (key_detect) begin
                row_idx <= first_low(row_n);
                col_idx <= col_state;
            end
        end
    end

    // map row/col to hex code
    function automatic [3:0] keymap (input [1:0] r, input [1:0] c);
        case ({r,c})
            4'b00_00: keymap = 4'h1; 4'b00_01: keymap = 4'h2;
            4'b00_10: keymap = 4'h3; 4'b00_11: keymap = 4'hA;
            4'b01_00: keymap = 4'h4; 4'b01_01: keymap = 4'h5;
            4'b01_10: keymap = 4'h6; 4'b01_11: keymap = 4'hB;
            4'b10_00: keymap = 4'h7; 4'b10_01: keymap = 4'h8;
            4'b10_10: keymap = 4'h9; 4'b10_11: keymap = 4'hC;
            4'b11_00: keymap = 4'hE; 4'b11_01: keymap = 4'h0;
            4'b11_10: keymap = 4'hF; 4'b11_11: keymap = 4'hD;
            default  : keymap = 4'h0;
        endcase
    endfunction

    // maintain stable key code while pressed
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_code <= 4'h0;
        else if (scan_tick && key_detect)
            key_code <= keymap(row_idx, col_idx);
    end

    // valid flag: registered for glitch-free output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            key_valid <= 1'b0;
        else if (scan_tick)
            key_valid <= key_detect;
    end

endmodule
