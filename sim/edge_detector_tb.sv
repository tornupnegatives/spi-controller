`timescale 1ns / 1ps

module edge_detector_tb;
    logic i_clk;
    logic i_rst_n;

    logic i_slow_clk;

    logic o_rising_edge;
    logic o_falling_edge;

    edge_detector DUT(
        .i_clk,
        .i_rst_n,
        .i_slow_clk,
        .o_rising_edge,
        .o_falling_edge
    );

    // 100 MHz fast clock
    always #5 i_clk = ~i_clk;
    // 25 MHz slow clock
    always #20 i_slow_clk = ~i_slow_clk;

    // Waveform generation
    initial begin
        $dumpfile("edge_detector.vcd");
        $dumpvars(0, edge_detector_tb);
    end

    initial begin
        $display("Simulation start");

        // Initial values
        i_clk = 0;
        i_rst_n = 1;
        i_slow_clk = 0;

        $display("Resetting...");
        @(negedge i_clk)
            i_rst_n = 0;
        
        repeat (16) @(negedge i_clk);

        @(negedge i_clk)
            i_rst_n = 1;

        repeat (100) begin
            @(posedge i_slow_clk)
                #1 assert(o_rising_edge === 1 && o_falling_edge === 0) else
                    $fatal(1, "Failed to detect rising edge");

            @(negedge i_slow_clk)
                #1 assert(o_rising_edge === 0 && o_falling_edge === 1) else
                    $fatal(1, "Failed to detect falling edge");

        end
        
        $display("Simulation finish");
        $finish;
    end
endmodule

