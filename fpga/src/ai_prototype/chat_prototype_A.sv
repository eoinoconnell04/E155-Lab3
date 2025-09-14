// -----------------------------------------------------------------------------
// clk_divider.sv
// Generic synchronous clock divider: derive an approx. OUT_FREQ from IN_FREQ.
// Produces a single-cycle pulse 'tick' at the requested rate.
// NOTE: OUT_FREQ should be << IN_FREQ and fit divider (IN_FREQ/OUT_FREQ).
// -----------------------------------------------------------------------------
module clk_divider #(
    parameter integer IN_FREQ_HZ  = 20_000_000, // input clock frequency (e.g. internal osc ~20 MHz)
    parameter integer OUT_FREQ_HZ = 150         // desired tick frequency (e.g. 100..200 Hz)
) (
    input  logic clk,
    input  logic rst_n,    // active-low reset
    output logic tick      // single-cycle pulse at OUT_FREQ_HZ
);

    // Compute divider count (rounding)
    localparam integer DIV = IN_FREQ_HZ / OUT_FREQ_HZ;
    // Avoid DIV == 0
    localparam integer CNT_WIDTH = $clog2(DIV <= 1 ? 2 : DIV);

    logic [CNT_WIDTH-1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= '0;
            tick <= 1'b0;
        end else begin
            if (cnt == DIV - 1) begin
                cnt  <= 0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1;
                tick <= 1'b0;
            end
        end
    end

endmodule


// -----------------------------------------------------------------------------
// keypad_scanner.sv
// Scans a 4x4 keypad: one active-low column at a time. Samples rows (active-low).
// Debounce-by-design: a candidate key must be stable for N_STABLE consecutive
// scan cycles to be registered. After registration we wait until no key is present
// (all rows high) before accepting another. Only one key is registered per press.
// -----------------------------------------------------------------------------
module keypad_scanner #(
    parameter integer N_STABLE = 3 // number of consecutive identical scans required to register
) (
    input  logic clk,          // system clock
    input  logic rst_n,        // active-low reset
    input  logic scan_tick,    // tick from clk_divider (100-200 Hz) to step scanning
    input  logic [3:0] rows,   // active-low inputs from keypad rows (1 = released, 0 = pressed)
    output logic [3:0] cols,   // active-low outputs to keypad columns; only one low at a time
    output logic new_key_valid,// one-cycle pulse when a new key is registered
    output logic [3:0] key_nib  // nibble 0x0..0xF for last registered key
);

    // Scan column index (0..3)
    logic [1:0] col_idx;

    // FSM for registration/debounce
    typedef enum logic [1:0] { IDLE, DEBOUNCE, REGISTERED, WAIT_RELEASE } state_t;
    state_t state;

    // Candidate key (row and col) captured during scans
    logic [1:0] cand_row;
    logic [1:0] cand_col;
    logic       cand_valid;

    // Debounce counter
    logic [$clog2(N_STABLE+1)-1:0] stable_cnt;

    // Helper: decode rows (active-low) to row index of first asserted (lowest index).
    // If multiple rows low, take first (lowest index) as per requirement "at most one key".
    function automatic logic [1:0] first_row_idx(input logic [3:0] r);
        if (!r[0]) first_row_idx = 2'd0;
        else if (!r[1]) first_row_idx = 2'd1;
        else if (!r[2]) first_row_idx = 2'd2;
        else first_row_idx = 2'd3;
    endfunction

    // Drive columns: one-hot active low (0 enables column)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_idx <= 2'd0;
            cols    <= 4'b1111;
        end else if (scan_tick) begin
            // rotate column on every scan tick
            col_idx <= col_idx + 1;
            case (col_idx + 1) // next active column (one-hot)
                2'd0: cols <= 4'b1110; // col0 active (low)
                2'd1: cols <= 4'b1101; // col1 active
                2'd2: cols <= 4'b1011; // col2 active
                2'd3: cols <= 4'b0111; // col3 active
                default: cols <= 4'b1110;
            endcase
        end
    end

    // Capture candidate key on each scan tick: if any row is low while a column is active,
    // note the col and row. cand_valid true when at least one row is low.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cand_valid  <= 1'b0;
            cand_row    <= 2'd0;
            cand_col    <= 2'd0;
        end else if (scan_tick) begin
            // rows are sampled while a single column is active (cols is one-hot low).
            if (rows != 4'b1111) begin
                cand_valid <= 1'b1;
                cand_row   <= first_row_idx(rows);
                // determine active column by reading cols (one-hot active low)
                unique case (cols)
                    4'b1110: cand_col <= 2'd0;
                    4'b1101: cand_col <= 2'd1;
                    4'b1011: cand_col <= 2'd2;
                    4'b0111: cand_col <= 2'd3;
                    default: cand_col <= 2'd0;
                endcase
            end else begin
                cand_valid <= 1'b0;
            end
        end
    end

    // FSM: debounce and register at most one key per press, wait for release.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            stable_cnt    <= '0;
            new_key_valid <= 1'b0;
            key_nib       <= 4'h0;
        end else begin
            // default
            new_key_valid <= 1'b0;

            case (state)
                IDLE: begin
                    stable_cnt <= '0;
                    if (cand_valid) begin
                        // start debouncing a candidate
                        state      <= DEBOUNCE;
                        // capture candidate details
                        // (cand_row/col already captured synchronously)
                        stable_cnt <= 1;
                    end
                end

                DEBOUNCE: begin
                    if (!cand_valid) begin
                        // candidate disappeared -> go back to IDLE
                        state      <= IDLE;
                        stable_cnt <= '0;
                    end else begin
                        // check if candidate still same row/col - because we captured cand_*
                        // and cand_valid is high, we treat same candidate across consecutive scans
                        if (stable_cnt + 1 >= N_STABLE) begin
                            // stable long enough -> register
                            // form nibble from row/col mapping (see mapping function below)
                            key_nib <= decode_nibble(cand_row, cand_col);
                            new_key_valid <= 1'b1;
                            state <= WAIT_RELEASE;
                        end else begin
                            stable_cnt <= stable_cnt + 1;
                        end
                    end
                end

                WAIT_RELEASE: begin
                    // ignore any further presses while any key is held.
                    if (!cand_valid) begin
                        // all keys released -> go back to IDLE to accept next press
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Key mapping (row, col) -> nibble. Choose a reasonable hex keypad mapping:
    // Rows top->bottom: row 0..3; Cols left->right: col 0..3.
    // Layout (visual):
    //   col0 col1 col2 col3
    // r0  1    2    3    A
    // r1  4    5    6    B
    // r2  7    8    9    C
    // r3  E    0    F    D
    function automatic logic [3:0] decode_nibble(input logic [1:0] r, input logic [1:0] c);
        casez ({r,c})
            4'b0000: decode_nibble = 4'h1; // r0 c0
            4'b0001: decode_nibble = 4'h2; // r0 c1
            4'b0010: decode_nibble = 4'h3; // r0 c2
            4'b0011: decode_nibble = 4'hA; // r0 c3

            4'b0100: decode_nibble = 4'h4; // r1 c0
            4'b0101: decode_nibble = 4'h5; // r1 c1
            4'b0110: decode_nibble = 4'h6; // r1 c2
            4'b0111: decode_nibble = 4'hB; // r1 c3

            4'b1000: decode_nibble = 4'h7; // r2 c0
            4'b1001: decode_nibble = 4'h8; // r2 c1
            4'b1010: decode_nibble = 4'h9; // r2 c2
            4'b1011: decode_nibble = 4'hC; // r2 c3

            4'b1100: decode_nibble = 4'hE; // r3 c0 ('*' -> E)
            4'b1101: decode_nibble = 4'h0; // r3 c1 (0)
            4'b1110: decode_nibble = 4'hF; // r3 c2 ('#' -> F)
            4'b1111: decode_nibble = 4'hD; // r3 c3 (D)
            default: decode_nibble = 4'h0;
        endcase
    endfunction

endmodule


// -----------------------------------------------------------------------------
// keypad_top.sv
// Top-level: ties the oscillator, clock dividers, keypad_scanner, and 2-digit
// multiplexed 7-segment display together.
// - Shows last two hex keys pressed: [older][most recent]
// - Balanced display brightness by equal on-time for each digit
// -----------------------------------------------------------------------------
module keypad_top #(
    // Adjust these per-board. IN_CLK_HZ should match the internal oscillator.
    parameter integer IN_CLK_HZ   = 20_000_000,
    // Keypad scan frequency: choose parent-specified 100..200 Hz
    parameter integer SCAN_HZ     = 150,
    // Display refresh frequency (multiplex switching). Each digit will see refresh=REFRESH_HZ/2.
    // Choose >=500-1000 Hz total to avoid flicker; 1000 Hz yields 500 Hz per digit.
    parameter integer REFRESH_HZ  = 1_000,
    // Debounce stability requirement (number of scan samples consistent)
    parameter integer DEBOUNCE_STABLE = 3,
    // Segment/digit polarities (set to match your hardware)
    parameter bit SEG_ACTIVE_LOW     = 1'b1, // if your 7-seg lines are active low
    parameter bit DIGIT_ACTIVE_LOW   = 1'b1  // if digit enable lines are active low
) (
    input  logic clk,         // internal oscillator (approx IN_CLK_HZ)
    input  logic rst_n,       // active-low reset
    input  logic [3:0] rows,  // keypad rows (active-low)
    output logic [3:0] cols,  // keypad cols (drive active-low)
    output logic [6:0] seg,   // 7-segment outputs (a,b,c,d,e,f,g) - polarity per parameter
    output logic [1:0] dig_en // two-digit enable lines (one-hot)
);

    // ---------------------------------------------------------------------
    // 1) Clock dividers
    // ---------------------------------------------------------------------
    logic scan_tick;
    logic refresh_tick;

    clk_divider #(.IN_FREQ_HZ(IN_CLK_HZ), .OUT_FREQ_HZ(SCAN_HZ)) scan_div (
        .clk(clk), .rst_n(rst_n), .tick(scan_tick)
    );

    clk_divider #(.IN_FREQ_HZ(IN_CLK_HZ), .OUT_FREQ_HZ(REFRESH_HZ * 2)) refresh_div (
        .clk(clk), .rst_n(rst_n), .tick(refresh_tick)
    );
    // We multiply REFRESH_HZ by 2 so refresh_tick cycles through both digits at REFRESH_HZ.

    // ---------------------------------------------------------------------
    // 2) Keypad scanner
    // ---------------------------------------------------------------------
    logic new_key_valid;
    logic [3:0] key_nib;

    keypad_scanner #(.N_STABLE(DEBOUNCE_STABLE)) scanner (
        .clk(clk), .rst_n(rst_n), .scan_tick(scan_tick),
        .rows(rows), .cols(cols),
        .new_key_valid(new_key_valid), .key_nib(key_nib)
    );

    // ---------------------------------------------------------------------
    // 3) Two-digit register: older and most_recent.
    // When a new key is registered, shift most_recent -> older, store new in most_recent.
    // ---------------------------------------------------------------------
    logic [3:0] digit_most, digit_old;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_most <= 4'h0;
            digit_old  <= 4'h0;
        end else begin
            if (new_key_valid) begin
                digit_old  <= digit_most;
                digit_most <= key_nib;
            end
        end
    end

    // ---------------------------------------------------------------------
    // 4) Display multiplexing
    // We use refresh_tick to alternate digits. Each refresh_tick is one digit time.
    // Keep duty equal for balanced brightness.
    // ---------------------------------------------------------------------
    logic current_digit; // 0 = lower/LSB digit (right), 1 = higher/MSB digit (left)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_digit <= 1'b0;
        else if (refresh_tick) current_digit <= ~current_digit;
    end

    // Choose which nibble to show this cycle
    logic [3:0] shown_nibble;
    always_comb begin
        shown_nibble = (current_digit ? digit_old : digit_most);
    end

    // 7-seg decoder (segments active-high by default, will invert if SEG_ACTIVE_LOW)
    function automatic logic [6:0] hex_to_seg(input logic [3:0] nib);
        // segment bits: {g,f,e,d,c,b,a} conventional order, but we will output a..g mapping below
        // We'll produce bits for a,b,c,d,e,f,g as seg[6:0] = {a,b,c,d,e,f,g} for clarity
        // Use common mapping: segments on (1) to display hex digit
        case (nib)
            4'h0: hex_to_seg = 7'b1111110; // 0: a b c d e f
            4'h1: hex_to_seg = 7'b0110000; // 1: b c
            4'h2: hex_to_seg = 7'b1101101; // 2: a b g e d
            4'h3: hex_to_seg = 7'b1111001; // 3: a b c d g
            4'h4: hex_to_seg = 7'b0110011; // 4: f g b c
            4'h5: hex_to_seg = 7'b1011011; // 5: a f g c d
            4'h6: hex_to_seg = 7'b1011111; // 6: a f e d c g
            4'h7: hex_to_seg = 7'b1110000; // 7: a b c
            4'h8: hex_to_seg = 7'b1111111; // 8: a b c d e f g
            4'h9: hex_to_seg = 7'b1111011; // 9
            4'hA: hex_to_seg = 7'b1110111; // A
            4'hB: hex_to_seg = 7'b0011111; // b (lowercase)
            4'hC: hex_to_seg = 7'b1001110; // C
            4'hD: hex_to_seg = 7'b0111101; // d (lowercase)
            4'hE: hex_to_seg = 7'b1001111; // E
            4'hF: hex_to_seg = 7'b1000111; // F
            default: hex_to_seg = 7'b0000000;
        endcase
    endfunction

    // Apply decoder and polarity inversion as parameterized
    logic [6:0] seg_raw; // a..g active-high
    always_comb begin
        seg_raw = hex_to_seg(shown_nibble);
        if (SEG_ACTIVE_LOW) begin
            // If hardware expects active-low segments, invert
            seg = ~seg_raw;
        end else begin
            seg = seg_raw;
        end
    end

    // Drive digit enables: two digits: [1] left (older), [0] right (most recent)
    // Active-low or active-high per parameter.
    always_comb begin
        if (current_digit == 1'b1) begin
            // show left digit (older) -> activate dig_en[1]
            if (DIGIT_ACTIVE_LOW) dig_en = 2'b01; // active low: assert 0 on digit[1], keep digit[0] high
            else                 dig_en = 2'b10; // active high: assert 1 on digit[1]
        end else begin
            // show right digit (most recent) -> activate dig_en[0]
            if (DIGIT_ACTIVE_LOW) dig_en = 2'b10; // assert 0 on digit[0] (we put bit order [1]=left,[0]=right)
            else                 dig_en = 2'b01;
        end
    end

endmodule
