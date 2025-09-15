/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 12, 2025
Module Function: This module takes the input of the current buttons being pressed,
and removes the jitter and returns the current value.
It also returns a boolean signal which is high for one cycle whenever a new key is pressed.

Parameter: CYCLE_WAIT_TIME, number of cycles to stay on a key before deciding it is not pressed (more cycles means more jitter resistance but slower operation)
*/

module jitter_controller     #(parameter CYCLE_WAIT_TIME=50)
(
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0]  keys_pressed,
    output logic [15:0]  key_pressed_value,
    output logic        new_key
);

    // Initiallize signal that is high when multiple keys are currently pressed
    logic multiple_keys_pressed;
    assign multiple_keys_pressed = (keys_pressed & (keys_pressed - 1)) != 0;

    typedef enum logic [0:0] {IDLE, ACTIVE} statetype;
    statetype state, next_state;

    // Counter
    logic [$clog2(CYCLE_WAIT_TIME)-1:0] counter;

    // Flag if any key is pressed
    logic keypad_nonzero;
    assign keypad_nonzero = |keys_pressed;

    // Remember the key that triggered ACTIVE state
    logic [15:0] active_key;

    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (keypad_nonzero)
                    next_state = ACTIVE;
            end

            ACTIVE: begin
                if (counter == CYCLE_WAIT_TIME)
                    next_state = IDLE;
            end
        endcase
    end

    // Counter logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (state == ACTIVE) begin
                if (keys_pressed == active_key)
                    counter <= 0; // only reset if same key still pressed
                else if (counter < CYCLE_WAIT_TIME)
                    counter <= counter + 1;
            end else begin
                counter <= 0;
            end
        end
    end

    // Output and active key logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_pressed_value <= 0;
            new_key <= 0;
            active_key <= 0;
        end else begin
            new_key <= 0;

            if (state == IDLE && keypad_nonzero && ~multiple_keys_pressed) begin
                key_pressed_value <= keys_pressed;
                active_key <= keys_pressed; // remember the key
                new_key <= 1;              // pulse new_key
            end
        end
    end

endmodule
