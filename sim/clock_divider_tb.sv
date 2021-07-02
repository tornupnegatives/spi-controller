`timescale 1ns / 1ps

module clock_divider_tb;
    logic i_clk;
    logic i_rst_n;
    logic [8:0] i_config;
    logic i_start_n;
    logic o_idle;
    logic o_clk;

    clock_divider DUT(
        .i_clk,
        .i_rst_n,
        .i_config,
        .i_start_n,
        .o_idle,
        .o_clk
    );

    // 50 MHz clock
    always #10 i_clk = ~i_clk;

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
        @(negedge i_clk)
            i_rst_n = 0;

        // Hold
        repeat (16) @(negedge i_clk);

        @(negedge i_clk)
            i_rst_n = 1;

        @(negedge i_clk) begin
            assert(o_idle && ~o_clk) else
                $fatal(1, "Failed to enter IDLE state after reset");
        end
    endtask

    task test_clock;
        input [7:0] divisor;
        $display("Running clock at %f MHz", 100.0/divisor);

        // Wait until ready
        if (~o_idle)
            @(posedge o_idle);

        @(negedge i_clk)
            i_start_n = 0;

        @(negedge i_clk)
            i_start_n = 1;

        repeat((divisor * 8))
            @(negedge i_clk)
                assert(~o_idle) else
                    $fatal(1, "Failed to run clock at %f MHz (early exit)", 100.0/divisor);

        @(negedge i_clk)
            assert(o_idle && ~o_clk) else
                $fatal(1, "Failed to run clock at %f MHz (late exit)", 100.0/divisor);
    endtask

    task configure;
        input [7:0] divisor;

        $display("Configuring...");

        @(negedge i_clk)
            i_config = {divisor, 1'h1};

        @(negedge i_clk)
            i_config = 0;

        // Wait until ready
        if (~o_idle)
            @(posedge o_idle);
    endtask
endmodule