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
    localparam [1:0]
        READY  = 2'b01,
        RUN    = 2'b10;

    // State machine
    reg [1:0] r_state, r_next_state;

    // Clock divisor
    reg [7:0]  r_cdiv, r_next_cdiv;

    // Counter
    reg [7:0] r_fast_cycle, r_next_fast;
    reg [7:0] r_slow_cycle, r_next_slow;

    // Slow clock
    reg r_clk, r_next_clk;
    reg r_rising_edge,  r_next_rising_edge;
    reg r_falling_edge, r_next_falling_edge;
    reg r_ready,        r_next_ready;

    // State machine logic
    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_state         <= READY;
            r_cdiv          <= 'h2;
            r_fast_cycle    <= 'h0;
            r_slow_cycle    <= 'h0;
            r_clk           <= 'h0;
            r_rising_edge   <= 'h0;
            r_falling_edge  <= 'h0;
            r_ready         <= 'h0;
        end

        else begin
            r_state         <= r_next_state;
            r_cdiv          <= r_next_cdiv;
            r_fast_cycle    <= r_next_fast;
            r_slow_cycle    <= r_next_slow;
            r_clk           <= r_next_clk;
            r_rising_edge   <= r_next_rising_edge;
            r_falling_edge  <= r_next_falling_edge;
            r_ready         <= r_next_ready;
        end
    end

    always @(*) begin
        // Defaults
        r_next_state        = r_state;
        r_next_cdiv         = r_cdiv;
        r_next_fast         = r_fast_cycle;
        r_next_slow         = r_slow_cycle;
        r_next_clk          = r_clk;
        r_next_rising_edge  = r_rising_edge;
        r_next_falling_edge = r_falling_edge;
        r_next_ready        = r_ready;

        case(r_state)
            READY: begin
                r_next_ready = i_rst_n;
                
                if (i_rst_n) begin
                    if (i_config[0]) begin
                        r_next_cdiv  = i_config[8:1];
                        r_next_state = READY;
                    end
                
                    else if (~i_start_n) begin
                        r_next_ready = 'h0;
                        r_next_state = RUN;

                        // For a half-speed clock, the next clock cycle will
                        // be the rising edge. Report it now!
                        if (r_cdiv == 2)
                            r_next_rising_edge = 'h1;
                    end
                end
             end

            RUN: begin
                // Stop clocking after 8 slow clocks
                if (r_slow_cycle == 16) begin
                    r_next_fast         = 'h0;
                    r_next_slow         = 'h0;
                    r_next_clk          = 'h0;
                    r_next_state = READY;
                end
                    
                // Toggle slow clock when fast clock hits divisor
                else begin
                    if (r_fast_cycle == r_cdiv / 2 - 1) begin
                        r_next_fast     = 'h0;
                        r_next_slow     = r_slow_cycle + 'h1;
                        r_next_clk      = ~r_clk;
                    end
                    
                    else begin
                        r_next_fast = r_fast_cycle + 'h1;
                    end
                end
                
                // Update edge detectors every clock cycle
                if (r_cdiv > 2) begin
                    r_next_rising_edge  = (r_fast_cycle == r_cdiv / 2 - 2) && r_slow_cycle != 16 ? ~r_clk   : 'h0;
                    r_next_falling_edge = (r_fast_cycle == r_cdiv / 2 - 2) && r_slow_cycle != 16 ? r_clk    : 'h0;
                end

                // For a half-speed clock, update edges early
                else begin
                    r_next_rising_edge  = (r_fast_cycle == r_cdiv / 2 - 1) && r_slow_cycle < 15 ? r_clk     : 'h0;
                    r_next_falling_edge = (r_fast_cycle == r_cdiv / 2 - 1) && r_slow_cycle < 16 ? ~r_clk    : 'h0;
                end
            end
        endcase
    end

    // Outputs
    assign o_ready = r_ready;
    assign o_clk = r_clk;
    assign o_clk_n = ~o_clk;
    assign o_slow_count = r_slow_cycle;
    assign o_rising_edge = r_rising_edge;
    assign o_falling_edge = r_falling_edge;
endmodule
