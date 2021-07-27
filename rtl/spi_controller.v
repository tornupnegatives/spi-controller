`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     SPI Controller
// Target Devices:  Xilinx Artix-7
// Description:     Configurable SPI controller
// Author:          Joseph Bellahcen <tornupnegatives@gmail.com>
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
        input [10:0]    i_config,

        // Device IO
        input [7:0]     i_tx,
        input           i_tx_valid,

        output [7:0]    o_rx,
        output          o_rx_valid,

        // SPI interface
        input           i_cipo,
        output          o_copi,
        output          o_sclk,

        // Status register
        output          o_ready
    );

    // States
    localparam [4:0]
        READY           = 5'b00001,
        RUN             = 5'b00010,
        FINAL_BIT       = 5'b00100,
        DATA_VALID      = 5'b01000,
        CLOCK_CONFIG    = 5'b10000;

    reg [4:0] r_state, r_next_state;

    // SPI configuration
    reg [1:0] r_spi_mode,   r_next_spi_mode;
    reg [7:0] r_cdiv,       r_next_cdiv;

    wire w_cphase, w_cpol;

    // Clock divider inputs
    reg [8:0]   r_sclk_config,  r_next_sclk_config;
    reg         r_sclk_start,   r_next_sclk_start;

    // Clock divider outputs
    wire [7:0]   w_sclk_count;
    wire         w_sclk_rising_edge, w_sclk_falling_edge;
    wire         w_sclk, w_sclk_n;

    // TX/RX
    reg [7:0] r_tx, r_next_tx;
    reg [7:0] r_rx, r_next_rx;

    // SPI
    reg r_copi, r_next_copi;

    // Status registers
    reg r_ready, r_next_ready;
    reg r_rx_valid, r_next_rx_valid;

    clock_divider cd(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_config(r_sclk_config),
        .i_start_n(r_sclk_start),

        .o_clk(w_sclk),
        .o_clk_n(w_sclk_n),

        .o_rising_edge(w_sclk_rising_edge),
        .o_falling_edge(w_sclk_falling_edge),
        .o_slow_count(w_sclk_count)
    );

    assign w_cphase = (r_spi_mode == 1) || (r_spi_mode == 3);
    assign w_cpol   = (r_spi_mode == 2) || (r_spi_mode == 3);

    always @(posedge i_clk) begin
        if (~i_rst_n) begin
            r_state         <= READY;
            r_spi_mode      <= 'h0;
            r_cdiv          <= 'h2;
            r_sclk_config   <= 'h0;
            r_sclk_start    <= 'h1;
            r_tx            <= 'h0;
            r_rx            <= 'h0;
            r_copi          <= 'h0;
            r_ready         <= 'h0;
            r_rx_valid      <= 'h0;
        end

        else begin
            r_state         <= r_next_state;
            r_spi_mode      <= r_next_spi_mode;
            r_cdiv          <= r_next_cdiv;
            r_sclk_config   <= r_next_sclk_config;
            r_sclk_start    <= r_next_sclk_start;
            r_tx            <= r_next_tx;
            r_rx            <= r_next_rx;
            r_copi          <= r_next_copi;
            r_ready         <= r_next_ready;
            r_rx_valid      <= r_next_rx_valid;
        end
    end

    always @(*) begin
        // Defaults
        r_next_state        = r_state;
        r_next_spi_mode     = r_spi_mode;
        r_next_cdiv         = r_cdiv;
        r_next_sclk_config  = r_sclk_config;
        r_next_sclk_start   = r_sclk_start;
        r_next_tx           = r_tx;
        r_next_rx           = r_rx;
        r_next_copi         = r_copi;
        r_next_ready        = r_ready;
        r_next_rx_valid     = r_rx_valid;

        case (r_state)
            READY: begin
                r_next_ready = i_rst_n;

                if (i_config[0]) begin
                    r_next_spi_mode = i_config[2:1];
                    r_next_cdiv = i_config[10:3];
                    r_next_sclk_config = {r_next_cdiv, 1'h1};

                    r_next_state = CLOCK_CONFIG;
                end

                else if (i_tx_valid) begin
                    r_next_tx = i_tx;
                    r_next_rx = 'h0;
                    r_next_rx_valid = 'h0;

                    r_next_state = RUN;
                end
            end

            CLOCK_CONFIG: begin
                r_next_sclk_config = 'h0;
                r_next_state = READY;
            end

            RUN: begin
                // Start clock
                r_next_sclk_start = 'h0;
                r_next_ready = 'h0;

                // Prepare for end of transmission
                if (w_sclk_count == 16) begin
                    // Stop clock
                    r_next_sclk_start = 'h1;

                    // If there is a phase, read the last
                    if (~w_cphase)
                        r_next_rx = {r_rx[6:0], i_cipo};

                    // Disable output
                    r_next_copi = 'h0;

                    r_next_state = FINAL_BIT;
                end

                // Always shift data out on rising edge
                if (w_sclk_rising_edge) begin
                    r_next_tx = r_tx << 1;
                    r_next_copi = r_tx[7];

                    // Sample if no phase
                    if (~w_cphase)
                        r_next_rx = {r_rx[6:0], i_cipo};
                end

                // Sample at falling edge if phase
                else if (w_sclk_falling_edge && w_cphase)
                    r_next_rx = {r_rx[6:0], i_cipo};
            end

            FINAL_BIT: begin
                // If there is a phase and polarity, sample one more time
                if (r_spi_mode == 3)
                    r_next_rx = {r_rx[6:0], i_cipo};

                r_next_state = DATA_VALID;
            end

            // Hold data valid signal for one clock cycle
            DATA_VALID: begin
                r_next_rx_valid = 'h1;
                r_next_state = READY;
            end
        endcase
    end

    // Outputs
    assign o_ready = r_ready;
    assign o_rx = r_rx;
    assign o_rx_valid = r_rx_valid;
    assign o_copi = r_copi;
    assign o_sclk = (w_cpol) ? w_sclk_n : w_sclk;
endmodule