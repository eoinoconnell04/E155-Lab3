/*
Author: Eoin O'Connell
Email: eoconnell@hmc.edu
Date: Sep. 12, 2025
Module Function: This module takes the input of the current buttons being pressed,
and removes the jitter and returns the current value.
It also returns a boolean signal which is high for one cycle whenever a new key is pressed.
*/

module jitter_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic [3:0]  keypad_sync,
    output logic [3:0]  key_pressed_value,
    output logic        new_key
);

    typedef enum logic [0:0] {IDLE, ACTIVE} statetype;
    statetype state, next_state;

    // How many cycles to wait before accepting a new key press
    localparam int cycle_wait_time = 50;

    // Counter
    logic [$clog2(cycle_wait_time)-1:0] counter;

    // Flag if any key is pressed
    logic keypad_nonzero;
    assign keypad_nonzero = |keypad_sync;

    // Remember the key that triggered ACTIVE state
    logic [3:0] active_key;

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
                if (counter == cycle_wait_time)
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
                if (keypad_sync == active_key)
                    counter <= 0; // only reset if same key still pressed
                else if (counter < cycle_wait_time)
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

            if (state == IDLE && keypad_nonzero) begin
                key_pressed_value <= keypad_sync;
                active_key <= keypad_sync; // remember the key
                new_key <= 1;              // pulse new_key
            end
        end
    end

endmodule
