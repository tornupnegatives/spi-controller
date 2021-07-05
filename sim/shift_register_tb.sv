`timescale 1ns / 1ps

module shift_register_tb;
    logic i_clk;
    logic i_rst_n;

    logic [1:0] i_mode;
    logic       i_output_enable_n;

    logic [7:0] i_parallel;
    logic       i_serial;

    logic [7:0] o_parallel;
    logic       o_serial;

    // Number of iterations per each task
    shortint unsigned n_trials;

    shift_register DUT(
        .i_clk,
        .i_rst_n,
        .i_mode,
        .i_output_enable_n,
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
        i_parallel = 0;
        i_serial = 0;

        test_reset;

        // Basic input tests (slow clock)
        for (int i = 0; i < n_trials; i++) begin
            test_shift($random, 1);
            test_parallel_load($random);
            test_shift($random, 0);
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
            i_output_enable_n = 1;
            i_parallel = value;
            i_mode = 2'b11;
        end

        @(negedge i_clk) begin
            i_mode = 0;
            i_output_enable_n = 0;
        end
        
        @(negedge i_clk);

        @(negedge i_clk) begin
            assert(o_parallel === value) else begin
                $display("Output mismatch: %d", o_parallel);
                $fatal(1, "Failed to parallel load");
            end
        end
    endtask

    task test_shift;
        input [7:0] value;
        input mode;

        // Generate random slow clock between 12.5 - 100 MHz
        //logic slow_clk;
        //static int slow_ratio = $urandom%70 + 10;

        $display("%s shifting %d...", mode?"Right":"Left", value);

        @(negedge i_clk) begin
            //i_slow_clk = 0;
            i_output_enable_n = 1;
            i_mode = mode ? 2'b01: 2'b10;
        end

        for (int i = 0; i < 8; i++) begin
            //#slow_ratio i_mode = mode ? 2'b01: 2'b10;
            @(negedge i_clk)
                i_serial = mode ? value[i] : value[7-i];
            //#slow_ratio i_mode = 0;
        end
        
        @(negedge i_clk) begin
            i_mode = 0;
            i_serial = 0;
            i_output_enable_n = 0;
        end
        
        @(negedge i_clk);
            
        @(negedge i_clk) begin
            assert(o_parallel === value) else begin
                $display("Output mismatch: %d", o_parallel);
                $fatal(1, "Failed to %s shift", mode?"right":"left");
            end
        end
    endtask
endmodule