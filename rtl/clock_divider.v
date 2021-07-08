`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     Clock Divider
// Target Devices:  Xilinx Artix-7
// Description:     Configurable, finite-pulse clock divider for use in a
//                  SPI environment
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
//
// Notes:           Configurable speed ranges from f_input/2 to f_input/255
//                  Divisor should be even and non-zero
//
//                  Generates 8 slow clocks and then idles
///////////////////////////////////////////////////////////////////////////////

module clock_divider
    (
        // FPGA interface
        input i_clk,
        input i_rst_n,

        // Control interface
        // ┌───────────────────────────┬────────────────────────┐
        // │         C8...C1           │           C0           │
        // ├───────────────────────────┼────────────────────────┤
        // │ Clock divisor (MSB...LSB) │ Register configuration │
        // └───────────────────────────┴────────────────────────┘
        input [8:0] i_config,
        input i_start_n,

        // Clock output
        output reg o_idle,
        output o_clk,
        output o_clk_n,
        
        // Metadata output
        output reg   o_rising_edge,
        output reg   o_falling_edge,
        output [7:0] o_slow_count
    );

    // Operational states
    localparam [1:0]
        RESET  = 0,
        IDLE   = 1,
        CONFIG = 2,
        RUN    = 3;

    // State machine
    reg [1:0] r_state;
    reg [1:0] r_next_state;

    // CLock divisor
    reg [7:0]  r_cdiv;

    // Counter
    reg [7:0] r_fast_cycle;
    reg [7:0] r_slow_cycle;
    reg [7:0] r_next_fast;
    reg [7:0] r_next_slow;

    // Slow clock
    reg r_clk;

    // State machine logic
    always @(posedge i_clk) begin
        if (~i_rst_n)
            r_state <= RESET;

        // Only accept config/start commands when IDLE
        else if (r_state == IDLE) begin
            // Register clock divisor (ensure even)
            if (i_config[0]) begin
                if (i_config[8:1] != 0)
                    r_cdiv <= (i_config[8:1] >> 1) - 1;
                    
                // Default slow clock is half speed
                else 
                    r_cdiv <= 0;
                    
                r_state <= CONFIG;
            end

            if (~i_start_n) begin
                r_state <= RUN;
            end
        end

        else
            r_state <= r_next_state;
    end

    // Counter
    always @(posedge i_clk) begin
        // Only count when RUNning
        if (r_state == RUN) begin
            if (r_fast_cycle != r_cdiv)
                r_fast_cycle <= r_next_fast;

            // Toggle slow clock when fast clock pulses div times
            else if (r_fast_cycle == r_cdiv) begin
                r_fast_cycle <= 0;
                r_slow_cycle <= r_next_slow;
                r_clk <= ~r_clk;
            end
        end

        else begin
            r_fast_cycle <= 0;
            r_slow_cycle <= 0;
            r_clk <= 0;
        end
    end

    always @(*) begin
        // Defaults
        o_idle = 1;
        o_rising_edge = 0;
        o_falling_edge = 0;
        r_next_fast = 0;
        r_next_slow = 0;
        r_next_state = r_state;

        case(r_state)
            RESET:
                r_next_state = IDLE;

            CONFIG: begin
                o_idle = 0;
                r_next_state = IDLE;
            end

            RUN: begin
                o_idle = 0;
                r_next_fast = r_fast_cycle + 1;

                // Enter idle state after 16 slow-clock edges
                if (r_slow_cycle == 16)
                    r_next_state = IDLE;

                else if (r_fast_cycle == r_cdiv) begin
                    r_next_slow = r_slow_cycle + 1;
                end
            end
        endcase
        
        if (r_clk && r_next_fast == r_cdiv + 1)
            o_falling_edge = 1;
        else if (~r_clk && r_next_fast == r_cdiv + 1)
            o_rising_edge = 1;

    end

    assign o_clk = r_clk;
    assign o_clk_n = ~o_clk;
    assign o_slow_count = r_slow_cycle;
endmodule
