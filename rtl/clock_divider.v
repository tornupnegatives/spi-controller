`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     Clock Divider
// Target Devices:  Xilinx Artix-7
// Description:     Configurable, finite-pulse clock divider for use in a
//                  SPI environment
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
//
// Notes:           Generates 8 slow clock pulses before entering IDLE state
//                  Max f_input = 50 MHz
//
//                  f_output = f_input / divisor
//
//                  The divisor should be an even number
//                  A divisor of 0 will result in a half-speed clock
///////////////////////////////////////////////////////////////////////////////

module clock_divider
    (
        input i_clk,
        input i_rst_n,

        // ┌───────────────────────────┬────────────────────────┐
        // │         C8...C1           │           C0           │
        // ├───────────────────────────┼────────────────────────┤
        // │ Clock divisor (MSB...LSB) │ Register configuration │
        // └───────────────────────────┴────────────────────────┘
        input [8:0] i_config,

        input i_start_n,

        output reg o_idle,
        output reg o_clk,
        output reg o_clk_n
    );

    localparam [1:0]
        RESET  = 0,
        IDLE   = 1,
        CONFIG = 2,
        RUN    = 3;

    reg [1:0] r_state;
    reg [1:0] r_next_state;

    //reg [7:0]  r_config;
    reg [7:0]  r_cdiv;

    reg [7:0] r_fast_cycle;
    reg [7:0] r_slow_cycle;
    reg r_clk;

    // State machine logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n)
            r_state <= RESET;

        else if (r_state == IDLE) begin
            if (i_config[0]) begin
                if (i_config[8:1] != 0)
                    r_cdiv = (i_config[8:1] >> 1) - 1;
                else 
                    r_cdiv = 0;
                    
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
        if (r_state == RUN) begin
            if (r_fast_cycle != r_cdiv)
                r_fast_cycle <= r_fast_cycle + 1;

            else if (r_fast_cycle == r_cdiv) begin
                r_fast_cycle <= 0;
                r_slow_cycle <= r_slow_cycle + 1;
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
        o_clk = 0;
        r_next_state = r_state;

        case(r_state)
            RESET:
                r_next_state = IDLE;

            CONFIG: begin
                o_idle = 0;
                o_clk = 0;

                r_next_state = IDLE;
            end

            RUN: begin
                o_idle = 0;

                if (r_slow_cycle == 16)
                    r_next_state = IDLE;
                else
                    o_clk = r_clk;
            end
        endcase

        // Inverted clock
        o_clk_n = ~o_clk;
    end
endmodule