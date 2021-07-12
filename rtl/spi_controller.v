`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     SPI Controller
// Target Devices:  Xilinx Artix-7
// Description:     Configurable SPI controller
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
//
// Notes:           Currently supports SPI MODE: 0, 1
//                  Current max clock ratio: 8
///////////////////////////////////////////////////////////////////////////////

module spi_controller(
        // FPGA interface
        input i_clk,
        input i_rst_n,

        // Configuration interface
        // ┌─────────────────┬────────────┬─────────────────────┐
        // │      10..3      │    2..1    │          0          │
        // ├─────────────────┼────────────┼─────────────────────┤
        // │ SPI clock ratio │ SPI mode   │ Store configuration │
        // │ Default: 2      │ Default: 0 │                     │
        // └─────────────────┴────────────┴─────────────────────┘
        input [10:0] i_config,

        // Device IO
        input [7:0] i_tx,
        input       i_tx_valid,

        output reg [7:0] o_rx,
        output reg       o_rx_valid,

        // SPI interface
        input i_cipo,
        output reg o_copi,
        output reg o_sclk,

        // Status register
        output reg o_ready
    );

    // Operational states
    localparam [2:0]
        RESET           = 'd0,
        READY           = 'd1,
        CONFIG          = 'd2,
        WAIT_FOR_CLOCK  = 'd3,
        TXRX            = 'd4,
        TXRX_FINAL      = 'd5,
        RX_VALID        = 'd6;

    reg [2:0] r_state;
    reg [2:0] r_next_state;

    // IO storage
    reg [9:0] r_config;
    reg [7:0] r_tx;
    reg [7:0] r_rx;
    reg       r_copi;

    // SPI configuration
    wire [1:0] w_spi_mode;
    wire [7:0] w_clk_ratio;
    wire       w_cpol;
    wire       w_cphase;

    // SPI clock generator
    reg [8:0]  r_clk_config;
    reg        r_clk_start;
    wire       w_clk_idle;
    wire       w_clk;
    wire       w_clk_n;
    wire       w_rising_edge;
    wire       w_falling_edge;
    wire [7:0] w_clk_count;

    clock_divider cd(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_config(r_clk_config),
        .i_start_n(r_clk_start),
        .o_idle(w_clk_idle),
        .o_clk(w_clk),
        .o_clk_n(w_clk_n),
        .o_rising_edge(w_rising_edge),
        .o_falling_edge(w_falling_edge),
        .o_slow_count(w_clk_count)
    );
    
    // Assignments
    assign w_spi_mode  = r_config[1:0];
    assign w_clk_ratio = r_config[9:2];
    assign w_cpol = (w_spi_mode == 2) || (w_spi_mode == 3);
    assign w_cphase = (w_spi_mode == 1) || (w_spi_mode == 3);

    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_config <= 10'b00000010_00;
            r_tx <= 0;
            r_rx <= 0;
            r_copi <= 0;
            r_state <= RESET;
        end

        else if (r_state == READY || r_state == RX_VALID) begin
            if (i_config[0]) begin
                r_config <= i_config[10:1];
                r_state <= CONFIG;
            end

            else if (i_tx_valid) begin
                r_rx <= 0;
                r_tx <= i_tx;
                r_state <= TXRX;
            end
        end

        else if (r_state == TXRX) begin
            if ((w_cphase && w_rising_edge) || (~w_cphase && w_falling_edge)) begin
                r_copi <= r_tx[7];
                r_tx <= r_tx << 1;
            end

            else if ((~w_cphase && w_rising_edge) || (w_cphase && w_falling_edge))
                r_rx <= {r_rx[6:0], i_cipo};

            r_state <= r_next_state;
        end

        else if (r_state == TXRX_FINAL) begin
            r_rx <= {r_rx[6:0], i_cipo};
            r_state <= r_next_state;
        end

        else begin
            r_copi <= 0;
            r_state <= r_next_state;
        end
    end

    always @(*) begin
        // Default register values
        r_clk_config = 0;
        r_clk_start = 1;
        r_next_state = r_state;

        // Update internal registers
        case (r_state)
            RESET: begin
                r_clk_start = 1;
                r_next_state = WAIT_FOR_CLOCK;
            end

            CONFIG: begin
                r_clk_config = {w_clk_ratio, 1'd1};

                // Wait for clock to enter CONFIG state
                if (w_clk_idle)
                    r_next_state = CONFIG;

                // Wait for clock to exit CONFIG state
                else if (~w_clk_idle)
                    r_next_state = WAIT_FOR_CLOCK;
            end

            WAIT_FOR_CLOCK: begin
                // Disable clock when it enters IDLE state
                if (w_clk_idle)
                    r_next_state = READY;
            end

            TXRX: begin
                r_clk_start = 0;

                if (w_clk_count == 15) begin
                    r_clk_start = 1;
                    r_next_state = TXRX_FINAL;
                end
            end

            TXRX_FINAL: r_next_state = RX_VALID;
        endcase

        // Set outputs
        o_ready     = (r_state == READY) || (r_state == RX_VALID);
        o_rx_valid  = (r_state == RX_VALID);
        o_rx        = r_rx;
        o_sclk      = w_cpol ? w_clk_n : w_clk;
        o_copi      = r_copi;
    end
endmodule