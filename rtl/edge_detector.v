`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     Edge Detector
// Target Devices:  Xilinx Artix-7
// Description:     Slow clock edge detector
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
///////////////////////////////////////////////////////////////////////////////

module edge_detector(
        // FPGA interface
        input i_clk,
        input i_rst_n,

        input i_slow_clk,

        output reg o_rising_edge,
        output reg o_falling_edge
    );

    reg r_delayed_clk;

    always @(posedge i_clk) begin
        if (~i_rst_n)
            r_delayed_clk <= 0;
        else
            r_delayed_clk <= i_slow_clk;    
    end

    assign o_rising_edge = i_slow_clk & ~r_delayed_clk;
    assign o_falling_edge = ~i_slow_clk & r_delayed_clk;

endmodule