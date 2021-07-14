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
    real t_in = 2.0;
    real t_out = 0.0;

    integer n_iter = 255;

    spi_controller DUT(
        .i_clk,
        .i_rst_n,
        .i_config,
        .i_tx,
        .i_tx_valid,
        .i_cipo,
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
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 1 TESTS");
        configure(1, 4);
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 2 TESTS");
        configure(2, 6);
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 3 TESTS");
        configure(3, 8);
        repeat (n_iter)
            send_byte($random, $random);

        reset;

        $display("Simulation finish");
        $finish;
    end

    task reset;
        $display("Resetting...");

        @(posedge i_clk)
            #t_in i_rst_n = 0;

        #105

        @(posedge i_clk)
            #t_in i_rst_n = 1;

        @(posedge i_clk) begin
            #t_out assert(o_ready) else
                $fatal(1, "Failed to reset");
        end
    endtask

    task configure;
        input [1:0] spi_mode;
        input [7:0] clk_ratio;

        $display("Configuring...");
        $display("MODE: %d, CLOCK SPEED: %f MHz", spi_mode, (1.0/clk_ratio) * 100);

        @(posedge i_clk)
            #t_in i_config = {clk_ratio, spi_mode, 1'b1};

        @(posedge i_clk)
            #t_in i_config = 'h0;

    endtask

    task send_byte;
        input [7:0] data;
        input [7:0] rx;

        $display("Sending x%x\tReceiving x%x", data, rx);

        @(posedge i_clk) begin
            i_tx = data;
            i_cipo = 0;
            #t_in i_tx_valid = 1;
        end
        
        // Wait for command to register
        if (o_ready)
            @(negedge o_ready)
                @(posedge i_clk)
                    i_tx_valid = 0;
                    
        // Send dummy peripheral data
        for (int i = 7; i >= 0; i--) begin
            @(posedge o_sclk) begin
                i_cipo = rx[i];
            end
        end

        // Wait for command to finish
        @(posedge o_rx_valid) begin
            @(posedge i_clk) begin
                $display("Received x%x", o_rx);
                #t_out assert(o_rx === rx) else $fatal(1);
            end
        end
    endtask
endmodule
