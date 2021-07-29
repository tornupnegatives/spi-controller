`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Module Name:     SPI Controller
// Target Devices:  Xilinx Artix-7, SAIL-IN Skywater RH90 Mantis
// Description:     Configurable SPI controller top module
//		    with synchronized inputs
//
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
///////////////////////////////////////////////////////////////////////////////


module spi_controller_top
    (
        input           i_clk,
        input           i_rst_n,

        input [10:0]    i_config,
        input [7:0]     i_tx,
        input           i_tx_valid,
    
        output [7:0]    o_rx,
        output          o_rx_valid,
        
        input           i_cipo,
        output          o_copi,
        output          o_sclk,
        
        output          o_ready
    );
    
    // Synchronized inputs
    reg [1:0] r_config_sync;
    reg [1:0] r_tx_valid_sync;
    reg [1:0] r_cipo_sync;
    
    spi_controller SC0(
    	.i_clk(i_clk),
    	.i_rst_n(i_rst_n),
    	.i_config({i_config[10:1], r_config_sync[1]}),   
    	.i_tx(i_tx),
    	.i_tx_valid(r_tx_valid_sync[1]),
    	.o_rx({o_rx}),
    	.o_rx_valid(o_rx_valid),
    	.i_cipo(r_cipo_sync[1]),
    	.o_copi(o_copi),
    	.o_sclk(o_sclk),
    	.o_ready(o_ready)
    );
    
    // Input synchronization
    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_config_sync   <= 2'b00;
            r_tx_valid_sync <= 2'b00;
            r_cipo_sync     <= 2'b00;
        end
        
        else begin
            r_config_sync   <= {r_config_sync[0], i_config[0]};
            r_tx_valid_sync <= {r_tx_valid_sync[0], i_tx_valid};
            r_cipo_sync     <= {r_cipo_sync[0], i_cipo};
        end
    end
endmodule
