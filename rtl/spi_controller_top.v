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
        input i_clk,
        input i_rst_n,
        
        input i_config_10,
        input i_config_9, 
        input i_config_8,
        input i_config_7,
        input i_config_6,
        input i_config_5,
        input i_config_4,
        input i_config_3,
        input i_config_2,
        input i_config_1,
        input i_config_0,
        
        input i_tx_7,
        input i_tx_6,
        input i_tx_5,
        input i_tx_4,
        input i_tx_3,
        input i_tx_2,
        input i_tx_1,
        input i_tx_0,
        
        input i_tx_valid,
        
        output o_rx_7,
        output o_rx_6,
        output o_rx_5,
        output o_rx_4,
        output o_rx_3,
        output o_rx_2,
        output o_rx_1,
        output o_rx_0,
        
        output o_rx_valid,
        
        input  i_cipo,
        output o_copi,
        output o_sclk,
        
        output o_ready
    );
    
    // Synchronized inputs
    reg [1:0] r_config_sync;
    reg [1:0] r_tx_valid_sync;
    reg [1:0] r_cipo_sync;
    
    spi_controller SC0(
    	.i_clk(i_clk),
    	.i_rst_n(i_rst_n),
    	
    	.i_config({i_config_10, i_config_9, i_config_8,
    			   i_config_7,  i_config_6, i_config_5,
    			   i_config_4,  i_config_3, i_config_2,
    			   i_config_1,  r_config_sync[1]}
    	),
    			   
    	.i_tx({i_tx_7, i_tx_6, i_tx_5, i_tx_4,
    		   i_tx_3, i_tx_2, i_tx_1, i_tx_0}),
    		   
    	.i_tx_valid(r_tx_valid_sync[1]),
    	
    	.o_rx({o_rx_7, o_rx_6, o_rx_5, o_rx_4,
    		   o_rx_3, o_rx_2, o_rx_1, o_rx_0}),
    		   
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
            r_config_sync   <= {r_config_sync[0], i_config_0};
            r_tx_valid_sync <= {r_tx_valid_sync[0], i_tx_valid};
            r_cipo_sync     <= {r_cipo_sync[0], i_cipo};
        end
    end
endmodule
