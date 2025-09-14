//------------------------------------------------------------------------------
// KeyPressOneShot
//------------------------------------------------------------------------------
// Generates a single-cycle "new_key" pulse when a stable key press is detected.
// While any key remains pressed, additional keys are ignored until all are
// released.  Simple 3-state FSM handles debounce and one-shot registration.
//------------------------------------------------------------------------------
//
// Parameters:
//   DEBOUNCE_BITS : width of the debounce counter.  The debounce time is
//                   (2^DEBOUNCE_BITS) * clk period.
//
// Inputs:
//   clk        : system clock
//   rst_n      : active-low synchronous reset
//   key_valid  : high when *any* key is currently detected (already
//                combined/decoded from your keypad scanner).
//   key_code   : code of the currently detected key (held stable by scanner).
//
// Outputs:
//   new_key    : single-cycle pulse when a *new* stable key is captured
//   key_latched: latched key code corresponding to the new_key pulse
//------------------------------------------------------------------------------
module KeyPressOneShot #(
    parameter int DEBOUNCE_BITS = 16  // adjust for your clock rate & switch bounce
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        key_valid,
    input  logic [3:0]  key_code,
    output logic        new_key,
    output logic [3:0]  key_latched
);

    // FSM states
    typedef enum logic [1:0] {
        IDLE,          // waiting for first press
        DEBOUNCE_PRESS,// key detected, waiting for stable press
        HELD,          // key held, wait for release
        DEBOUNCE_REL   // waiting for stable release
    } state_t;

    state_t state, next_state;

    // debounce counter
    logic [DEBOUNCE_BITS-1:0] cnt;
    logic cnt_done = (cnt == {DEBOUNCE_BITS{1'b1}});

    // latch for key code
    logic [3:0] key_reg;

    // next-state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (key_valid) next_state = DEBOUNCE_PRESS;
            end
            DEBOUNCE_PRESS: begin
                if (!key_valid)         next_state = IDLE;          // bounced open
                else if (cnt_done)      next_state = HELD;          // stable press
            end
            HELD: begin
                if (!key_valid)         next_state = DEBOUNCE_REL;  // possible release
            end
            DEBOUNCE_REL: begin
                if (key_valid)          next_state = HELD;          // bounced closed
                else if (cnt_done)      next_state = IDLE;          // stable release
            end
        endcase
    end

    // sequential logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state        <= IDLE;
            cnt          <= '0;
            key_reg      <= '0;
            new_key      <= 1'b0;
            key_latched  <= '0;
        end
        else begin
            state <= next_state;

            // counter: run in debounce states
            if (state==DEBOUNCE_PRESS || state==DEBOUNCE_REL) begin
                if (cnt_done) cnt <= cnt;   // hold at max
                else          cnt <= cnt + 1'b1;
            end
            else begin
                cnt <= '0;
            end

            // latch key code on first stable press
            if (state==DEBOUNCE_PRESS && cnt_done) begin
                key_reg <= key_code;
            end

            // generate single-cycle pulse when transitioning to HELD
            new_key <= (state==DEBOUNCE_PRESS && cnt_done);

            // update output code when pulse occurs
            if (state==DEBOUNCE_PRESS && cnt_done) begin
                key_latched <= key_code;
            end
        end
    end

endmodule
