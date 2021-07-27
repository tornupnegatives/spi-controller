`timescale 1ns / 1ps

module clock_divider_tb;
    logic i_clk;
    logic i_rst_n;
    logic [8:0] i_config;
    logic i_start_n;
    logic o_ready;
    logic o_clk;

    clock_divider DUT(
        .i_clk,
        .i_rst_n,
        .i_config,
        .i_start_n,
        .o_ready,
        .o_clk
    );

    // 100 MHz clock
    always #5 i_clk = ~i_clk;
    real t_in = 2.0;
    real t_out = 0.0;

    // Waveform generation
    initial begin
        $dumpfile("clock_divider.vcd");
        $dumpvars(0, clock_divider_tb);
    end

    initial begin
        $display("Simulation start");

        // Initial values
        i_clk = 0;
        i_rst_n = 1;
        i_config = 0;
        i_start_n = 1;
        
        test_reset;
        
        // 0.4 MHz
        configure(250);
        test_clock(250);
        
        // 1 MHz
        configure(100);
        test_clock(100);

        // 25 MHz
        configure(4);
        test_clock(4);

        // 50 MHz
        configure(2);
        test_clock(2);
        
        $display("Simulation finish");
        $finish;
    end

    task test_reset;
        $display("Resetting...");
        @(posedge i_clk)
            #t_in i_rst_n = 0;

        // Hold
        repeat (16) @(posedge i_clk);

        repeat (5) @(posedge i_clk)
            #t_in i_rst_n = 1;

        @(posedge i_clk) begin
            #t_out assert(~o_clk) else
                $fatal(1, "Failed to enter IDLE state after reset");
        end
    endtask

    task test_clock;
        input [7:0] divisor;
        
        $display("Running clock at %f MHz", 100.0/divisor);

        @(posedge i_clk)
            #t_in i_start_n = 0;

        if (o_ready)
            @(negedge o_ready)
                @(posedge i_clk)
                    #t_in i_start_n = 1;

        repeat((divisor * 8) - 1) @(posedge i_clk)
            #t_out assert(~o_ready) else
                $fatal(1, "Failed to run clock at %f MHz (early exit)", 100.0/divisor);
        
        @(posedge i_clk);
        
        @(posedge i_clk)
            #t_out assert(o_ready && ~o_clk) else
                $fatal(1, "Failed to run clock at %f MHz (late exit)", 100.0/divisor);
    endtask

    task configure;
        input [7:0] divisor;

        $display("Configuring...");

        @(posedge i_clk)
            #t_in i_config = {divisor, 1'h1};
            
        @(posedge i_clk)
            #t_in i_config = 'h0;
            
    endtask
endmodule
