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

    reg [2:0] r_delayed_clk;

    always @(posedge i_clk) begin
        if (~i_rst_n)
            r_delayed_clk <= 0;
        else
            r_delayed_clk <= {i_slow_clk, r_delayed_clk[2:1]};    
    end

    assign o_rising_edge = (~r_delayed_clk[1] & r_delayed_clk[0]) & i_rst_n;
    assign o_falling_edge = (r_delayed_clk[1] & ~r_delayed_clk[0]) & i_rst_n;

endmodule