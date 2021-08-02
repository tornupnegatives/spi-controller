`timescale 1ns / 1ps

module spi_controller_tb;
    logic           i_clk;
    logic           i_rst_n;
    logic           i_request_tx;
    logic           i_ws_n;
    logic           i_rs_n;
    logic [2:0]     i_addr;
    logic [7:0]     i_data;
    logic [7:0]     o_data;
    logic           i_cipo;
    logic           o_copi;
    logic           o_sclk;
    logic           o_ready;
    logic           o_rx_valid;

    // 100 MHz clock
    always #5 i_clk = ~i_clk;
    real t_in = 2.0;
    real t_out = 0.0;

    integer n_iter = 255;

    spi_controller_top DUT(.*);

    initial begin
        $dumpfile("spi_controller.vcd");
        $dumpvars(0, spi_controller_tb);
    end

    initial begin
        $display("Simulation start");
        i_clk           = 'h0;
        i_rst_n         = 'h1;
        i_request_tx    = 'h0;
        i_ws_n          = 'h1;
        i_rs_n          = 'h1;
        i_addr          = 'h0;
        i_data          = 'h0;
        i_cipo          = 'h0;

        reset;

        $display("MODE 0 TESTS");
        configure(0, 4);
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 1 TESTS");
        configure(1, 8);
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 2 TESTS");
        configure(2, 12);
        repeat (n_iter)
            send_byte($random, $random);

        $display("MODE 3 TESTS");
        configure(3, 16);
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

        repeat (3) @(posedge i_clk)
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

        repeat (2) @(posedge i_clk) begin
            i_addr = 'h3;
            i_data = spi_mode;
            #t_in i_ws_n = 'h0;
        end

        @(posedge i_clk)
            #t_in i_ws_n = 'h1;

        repeat (2) @(posedge i_clk) begin
            i_addr = 'h4;
            i_data = clk_ratio;
            #t_in i_ws_n = 'h0;
        end

        @(posedge i_clk)
            #t_in i_ws_n = 'h1;

        i_addr = 'h0;
        i_data = 'h0;
    endtask

    task send_byte;
        input [7:0] data;
        input [7:0] rx;

        $display("Sending x%x\tReceiving x%x", data, rx);

        @(posedge i_clk) begin
            i_data = data;
            i_cipo = 'h0;
            #t_in i_request_tx = 'h1;
        end
        
        // Wait for command to register
        if (o_ready)
            @(negedge o_ready)
                @(posedge i_clk)
                    i_request_tx = 'h0;
                    
        // Send dummy peripheral data
        for (int i = 7; i >= 0; i--) begin
            @(posedge o_sclk) begin
                #t_in i_cipo = rx[i];
            end
        end

        // Wait for command to finish
        @(posedge o_rx_valid) begin
            @(posedge i_clk)
                #t_in i_cipo = 'h0;
                
            @(posedge i_clk) begin
                $display("Received x%x", o_data);
                #t_out assert(o_data === rx) else $fatal(1);
            end
        end
    endtask
endmodule
