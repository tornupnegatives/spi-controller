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
        output o_ready,
        output o_clk,
        output o_clk_n,
        
        // Metadata output
        output       o_rising_edge,
        output       o_falling_edge,
        output [7:0] o_slow_count
    );

    // Operational states
    localparam [3:0]
        RESET  = 4'b0000,
        READY  = 4'b0010,
        CONFIG = 4'b0100,
        RUN    = 4'b1000;

    // State machine
    reg [3:0] r_state;
    reg [3:0] r_next_state;

    // CLock divisor
    reg [8:0]  r_config;
    reg [7:0]  r_cdiv;
    reg [7:0]  r_next_cdiv;

    // Counter
    reg [7:0] r_fast_cycle;
    reg [7:0] r_slow_cycle;
    reg [7:0] r_next_fast;
    reg [7:0] r_next_slow;

    // Slow clock
    reg r_clk;
    reg r_rising_edge;
    reg r_falling_edge;

    // State machine logic
    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_cdiv <= 0;
            r_config <= 0;
            r_state <= RESET;
        end
       
        else if (r_state == READY) begin
            r_config <= i_config;
            r_state <= r_next_state;
        end

        else if (r_state == CONFIG) begin
            r_cdiv <= r_next_cdiv;
            r_state <= r_next_state;
        end

        else
            r_state <= r_next_state;
    end

    // Counter
    always @(posedge i_clk) begin
        // Only count when running
        if (r_state == RUN && r_next_state != READY) begin
            if (r_fast_cycle != r_cdiv)
                r_fast_cycle <= r_next_fast;

            // Toggle slow clock when fast clock pulses cdiv times
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
        r_rising_edge = 0;
        r_falling_edge = 0;
        r_next_fast = 0;
        r_next_slow = 0;
        r_next_cdiv = r_cdiv;
        r_next_state = r_state;

        case(r_state)
            RESET:
                r_next_state = READY;

            CONFIG: begin
                r_next_cdiv  = (r_config[8:1] >> 1) - 1;
                r_next_state = READY;
            end

            RUN: begin
                r_next_fast = r_fast_cycle + 1;

                // Enter idle state after 16 slow-clock edges
                if (r_slow_cycle == 16)
                    r_next_state = READY;

                else if (r_fast_cycle == r_cdiv) begin
                    r_next_slow = r_slow_cycle + 1;
                end

                // Track edges
                if (r_clk && r_next_fast == r_cdiv + 1)
                    r_falling_edge = 1;
                else if (~r_clk && r_next_fast == r_cdiv + 1)
                    r_rising_edge = 1;
            end

            READY: begin
                if (r_config[0])
                    r_next_state = CONFIG;

                else if (~i_start_n)
                    r_next_state = RUN;

            end
        endcase
    end

    // Outputs
    assign o_ready = (r_state == READY);
    assign o_clk = r_clk;
    assign o_clk_n = ~o_clk;
    assign o_slow_count = r_slow_cycle;
    assign o_rising_edge = r_rising_edge;
    assign o_falling_edge = r_falling_edge;
endmodule
