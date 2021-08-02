`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Module Name:     SPI Controller
// Target Devices:  Xilinx Artix-7, SAIL-IN Skywater RH90 Mantis
// Description:     Configurable SPI controller top module
//		    with synchronized inputs
//
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
///////////////////////////////////////////////////////////////////////////////


module spi_controller_top(
        // FPGA interface
        input i_clk,
        input i_rst_n,

        // Control interface
        input           i_request_tx,
        input           i_ws_n,
        input           i_rs_n,
        input [2:0]     i_addr,

        // Data busses
        input   [7:0]     i_data,
        output  [7:0]     o_data,

        // SPI
        input   i_cipo,
        output  o_copi,
        output  o_sclk,
        output  o_cs_n,

        // Status registers
        output o_ready,
        output o_rx_valid
    );

    // Debug registers (read-only)
    wire [7:0] w_whoami;

    // Control registers (read-write)
    reg [1:0] r_spi_mode,       r_next_spi_mode;
    reg [7:0] r_clk_div,        r_next_clk_div;
    reg       r_config_flag,    r_next_config_flag;

    // Data bus output
    wire [7:0] w_spi_rx;
    reg  [7:0] r_data, r_next_data;
    
    // Synchronized inputs
    wire w_request_tx_sync;
    wire w_ws_n_sync, w_rs_n_sync;
    wire w_cipo_sync;
    wire w_cipo;
    sync S0(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_sig(i_request_tx), .o_stable(w_request_tx_sync));
    sync S1(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_sig(i_ws_n),       .o_stable(w_ws_n_sync));
    sync S2(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_sig(i_rs_n),       .o_stable(w_rs_n_sync));
    sync S3(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_sig(i_cipo),       .o_stable(w_cipo_sync));
    
    spi_controller SC(
    	.i_clk(i_clk),
    	.i_rst_n(i_rst_n),
    	.i_config({r_clk_div, r_spi_mode, r_config_flag}),   
    	.i_tx(i_data),
    	.i_tx_valid(i_request_tx),
    	.o_rx(w_spi_rx),
    	.o_rx_valid(o_rx_valid),
    	.i_cipo(w_cipo),
    	.o_copi(o_copi),
    	.o_sclk(o_sclk),
    	.o_ready(o_ready)
    );

    // FSM
    localparam [5:0]
        READY       = 6'b000001,
        REQUEST_TX  = 6'b000010,
        SPI_RUN     = 6'b000100,
        READ_REG    = 6'b001000,
        WRITE_REG   = 6'b010000,
        CONFIG      = 6'b100000;

    reg [5:0] r_state, r_next_state;

    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_state         <= READY;
            r_spi_mode      <= 'h0;
            r_clk_div       <= 'h2;
            r_config_flag   <= 'h0;
            r_data          <= 'h0;
        end

        else begin
            r_state         <= r_next_state;
            r_spi_mode      <= r_next_spi_mode;
            r_clk_div       <= r_next_clk_div;
            r_config_flag   <= r_next_config_flag;
            r_data          <= r_next_data;
        end
    end

    always @(*) begin
        r_next_state        = r_state;
        r_next_spi_mode     = r_spi_mode;
        r_next_clk_div      = r_clk_div;
        r_next_config_flag  = r_config_flag;
        r_next_data         = r_data;

        case (r_state)
            READY: begin
                if (w_request_tx_sync)
                    r_next_state = REQUEST_TX;

                else if (~w_rs_n_sync)
                    r_next_state = READ_REG;

                else if (~w_ws_n_sync)
                    r_next_state = WRITE_REG;

                else if (o_rx_valid)
                    r_next_data = w_spi_rx;
            end

            REQUEST_TX: begin
                r_next_state = o_ready ? SPI_RUN : READY;
            end

            SPI_RUN: begin
                if (o_rx_valid) begin
                    r_next_data = w_spi_rx;
                    r_next_state = READY;
                end
            end

            READ_REG: begin
                case (i_addr)
                    0:  r_next_data = 'h0;
                    1:  r_next_data = 'hff;
                    2:  r_next_data = w_whoami;
                    3:  r_next_data = r_spi_mode;
                    4:  r_next_data = r_clk_div;
                endcase
                
                r_next_state = READY;
            end

            WRITE_REG: begin
                case (i_addr)
                    3:  r_next_spi_mode = i_data[1:0];
                    4:  r_next_clk_div  = i_data;
                endcase

                r_next_config_flag = 'h1;
                r_next_state = CONFIG;
            end

            CONFIG: begin
                r_next_config_flag = 'h0;
                r_next_state = READY;
            end
        endcase
    end
    
    // For a half-speed clock, there is not enough time to sync inputs
    assign w_cipo = (r_clk_div == 'h2) ? i_cipo : w_cipo_sync;

    // Debug registers
    assign w_whoami = 8'hA7;

    // Outputs
    assign o_data = r_data;
    assign o_cs_n = o_ready;
endmodule
