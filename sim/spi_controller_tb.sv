`timescale 1ns / 1ps

module spi_controller_tb;
    logic           i_clk;
    logic           i_rst_n;
    logic [10:0]    i_config;
    logic [7:0]     i_tx;
    logic           i_tx_valid;
    logic           i_cipo;
    logic           o_ready;
    logic [7:0]     o_rx;
    logic           o_rx_valid;
    logic           o_copi;
    logic           o_sclk;

    // 100 MHz clock
    always #5 i_clk = ~i_clk;

    spi_controller DUT(
        .i_clk,
        .i_rst_n,
        .i_config,
        .i_tx,
        .i_tx_valid,
        .i_cipo(o_copi),
        .o_ready,
        .o_rx,
        .o_rx_valid,
        .o_copi,
        .o_sclk
    );

    initial begin
        $dumpfile("spi_controller.vcd");
        $dumpvars(0, spi_controller_tb);
    end

    initial begin
        $display("Simulation start");
        i_clk = 0;
        i_rst_n = 1;
        i_config = 0;
        i_tx = 0;
        i_tx_valid = 0;
        i_cipo = 0;

        reset;

        $display("MODE 0 TESTS");
        configure(0, 2);
        repeat (5)
            send_byte($random);

        $display("MODE 1 TESTS");
        configure(1, 4);
        repeat (5)
            send_byte($random);

        /*
        $display("MODE 2 TESTS");
        configure(2, 6);
        repeat (5)
            send_byte($random);
        */

        reset;

        $display("Simulation finish");
        $finish;
    end

    task reset;
        $display("Resetting...");

        @(posedge i_clk)
            i_rst_n = 0;

        #105

        @(posedge i_clk)
            i_rst_n = 1;

        if (~o_ready)
            @(posedge o_ready);
    endtask

    task configure;
        input [1:0] spi_mode;
        input [7:0] clk_ratio;

        $display("Configuring...");
        $display("MODE: %d, CLOCK SPEED: %f MHz", spi_mode, (1.0/clk_ratio) * 100);

        @(posedge i_clk)
            i_config = {clk_ratio, spi_mode, 1'b1};

        // Wait for command to register
        if (o_ready)
            @(negedge o_ready)
                @(posedge i_clk)
                    i_config = 0;

        // Wait for command to finish
        if (~o_ready)
            @(posedge o_ready);
    endtask

    task send_byte;
        input [7:0] data;

        $display("Sending x%x", data);

        @(posedge i_clk) begin
            i_tx = data;
            i_cipo = 0;
            i_tx_valid = 1;
        end
        
        // Wait for command to register
        if (o_ready)
            @(negedge o_ready)
                @(posedge i_clk)
                    i_tx_valid = 0;

        // Wait for command to finish
        if (~o_ready)
            @(posedge o_ready);

        $display("Received x%x", o_rx);

        assert(o_rx === data) else
            $fatal(1, "Received x%x", o_rx);
    endtask
endmodule
