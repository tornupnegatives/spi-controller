`timescale 1ns / 1ps

module shift_register_tb;
    logic i_clk;
    logic i_rst_n;

    logic [1:0] i_mode;
    logic       i_output_enable_n;
    logic       i_slow_clk;

    logic [7:0] i_parallel;
    logic       i_serial;

    logic [7:0] o_parallel;
    logic       o_serial;

    shortint unsigned n_trials;

    shift_register DUT(
        .i_clk,
        .i_rst_n,
        .i_mode,
        .i_output_enable_n,
        .i_slow_clk,
        .i_parallel,
        .i_serial,
        .o_parallel,
        .o_serial
    );

    // 100 MHz clock
    always #5 i_clk = ~i_clk;

    // Waveform generation
    initial begin
        $dumpfile("shift_register.vcd");
        $dumpvars(0, shift_register_tb);
    end

    initial begin
        $display("Simulation start");

        n_trials = 100;

        i_clk = 0;
        i_rst_n = 1;
        i_mode = 0;
        i_output_enable_n = 1;
        i_slow_clk = 0;
        i_parallel = 0;
        i_serial = 0;

        test_reset;

        // Basic functionality tests
        for (int i = 0; i < n_trials; i++) begin
            test_right_shift($random);
            test_parallel_load($random);
            test_left_shift($random);
        end

        test_reset;
        
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
            assert(o_parallel === 0 && o_serial === 0) else
                $fatal(1, "Failed to enter known state after reset");
        end
    endtask

    task test_parallel_load;
        input [7:0] value;

        $display("Parallel loading %d...", value);

        @(negedge i_clk) begin
            i_parallel = value;
            i_mode = 2'b11;
        end

        @(negedge i_clk) begin
            i_mode = 0;
            i_output_enable_n = 0;
        end

        @(negedge i_clk) begin
            i_output_enable_n = 1;
            assert(o_parallel === value) else begin
                $display("Output mismatch: %d", o_parallel);
                $fatal(1, "Failed to parallel load");
            end
        end
    endtask

    task test_right_shift;
        input [7:0] value;

        $display("Right shifting %d...", value);

        @(negedge i_clk)
            i_mode = 2'b01;

        for (int i = 0; i < 8; i++) begin
            @(negedge i_clk) begin
                i_slow_clk = 1;
                i_serial = value[i];

                #3 i_slow_clk = 0;
            end
        end

        @(negedge i_clk) begin
            i_mode = 0;
            i_serial = 0;
            i_output_enable_n = 0;
        end

        @(negedge i_clk) begin
            i_output_enable_n = 1;
            assert(o_parallel === value) else begin
                $display("Output mismatch: %d", o_parallel);
                $fatal(1, "Failed to right shift");
            end
        end
    endtask

    task test_left_shift;
        input [7:0] value;

        $display("Left shifting %d...", value);

        @(negedge i_clk)
            i_mode = 2'b10;

        for (int i = 0; i < 8; i++) begin
            @(negedge i_clk) begin
                i_slow_clk = 1;
                i_serial = value[7-i];

                #3 i_slow_clk = 0;
            end
        end

        @(negedge i_clk) begin
            i_mode = 0;
            i_serial = 0;
            i_output_enable_n = 0;
        end

        @(negedge i_clk) begin
            i_output_enable_n = 1;
            assert(o_parallel === value) else begin
                $display("Output mismatch: %d", o_parallel);
                $fatal(1, "Failed to left shift");
            end
        end
    endtask
endmodule