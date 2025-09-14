//------------------------------------------------------------------------------
// keypad_display_top
//------------------------------------------------------------------------------
// * Root clock: iCE40 internal HFOSC (~12 MHz default)
// * Instantiates:
//      - KeypadScanner    : 4x4 matrix scanner (active-low)
//      - KeyPressOneShot  : debounced one-shot new-key detector
//      - sevenSegment     : combinational decoder (assumed provided)
//
// * Maintains last two keys pressed and displays them on a multiplexed
//   two-digit 7-segment display (common-anode or common-cathode driven
//   by seg/ an_en outputs as appropriate).
//------------------------------------------------------------------------------
module keypad_display_top (
    input  logic        rst_n,     // active-low reset

    // 4x4 keypad connections
    output logic [3:0]  col_n,     // active-low column drives
    input  logic [3:0]  row_n,     // active-low row inputs

    // Seven-segment display interface
    output logic [6:0]  seg,       // segments a..g (assumed active-high)
    output logic [1:0]  dig_an     // digit enable (active-low for common-anode)
);

    //======================================================================
    // 1. Internal HFOSC (approx 12 MHz) as root clock
    //======================================================================
    wire clk_12m;
    SB_HFOSC #(
        .CLKHF_DIV("0b00")   // 00 = 12 MHz, 01 = 6 MHz, 10 = 3 MHz, 11 = 1.5 MHz
    ) hfosc_inst (
        .CLKHFPU(1'b1),      // power up
        .CLKHFEN(1'b1),      // enable
        .CLKHF(clk_12m)
    );

    //======================================================================
    // 2. Keypad scanner + one-shot
    //======================================================================
    logic        key_valid;
    logic [3:0]  key_code;
    logic        new_key;
    logic [3:0]  key_latched;

    // Keypad scanner (≈500 Hz scan rate)
    KeypadScanner #(
        .CLK_DIV(12_000) // ~500 Hz/column at 12 MHz
    ) scanner_i (
        .clk      (clk_12m),
        .rst_n    (rst_n),
        .col_n    (col_n),
        .row_n    (row_n),
        .key_valid(key_valid),
        .key_code (key_code)
    );

    // One-shot debouncer
    KeyPressOneShot #(
        .DEBOUNCE_BITS(16)   // ~5 ms debounce at 12 MHz
    ) oneshot_i (
        .clk        (clk_12m),
        .rst_n      (rst_n),
        .key_valid  (key_valid),
        .key_code   (key_code),
        .new_key    (new_key),
        .key_latched(key_latched)
    );

    //======================================================================
    // 3. Last-two-keys shift register
    //======================================================================
    logic [3:0] most_recent, older;

    always_ff @(posedge clk_12m or negedge rst_n) begin
        if (!rst_n) begin
            most_recent <= 4'h0;
            older       <= 4'h0;
        end
        else if (new_key) begin
            older       <= most_recent;
            most_recent <= key_latched;
        end
    end

    //======================================================================
    // 4. 7-segment display multiplex
    //    Goal: >1 kHz per digit (~2 kHz total) for flicker-free display.
    //======================================================================
    localparam integer REFRESH_DIV = 6000; // 12 MHz / 6000 ≈ 2 kHz toggle rate

    logic [$clog2(REFRESH_DIV)-1:0] refresh_cnt;
    logic                           mux_sel;

    always_ff @(posedge clk_12m or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt <= '0;
            mux_sel     <= 1'b0;
        end else begin
            if (refresh_cnt == REFRESH_DIV-1) begin
                refresh_cnt <= '0;
                mux_sel     <= ~mux_sel;   // toggle active digit
            end else begin
                refresh_cnt <= refresh_cnt + 1'b1;
            end
        end
    end

    // digit data: older on left, most_recent on right
    logic [3:0] active_nibble = mux_sel ? most_recent : older;

    // 7-seg decoder (assumed combinational)
    sevenSegment segdec (
        .bin (active_nibble),
        .seg (seg)
    );

    // active-low digit enables: dig_an[1] = left, dig_an[0] = right
    always_comb begin
        case (mux_sel)
            1'b0: dig_an = 2'b10; // left digit on
            1'b1: dig_an = 2'b01; // right digit on
        endcase
    end

endmodule
