`timescale 1ns/1ps

module shift_register_tb;
    logic i_clk;
    logic i_rst_n;
    logic i_s0;
    logic i_s1;
    logic i_oe0;
    logic i_oe1;

    logic [7:0] i_parallel;
    logic       i_serial;
    logic [7:0] o_parallel;
    logic       o_serial;

    shift_register DUT(
        .i_clk,
        .i_rst_n,
        .i_s0,
        .i_s1,
        .i_oe0,
        .i_oe1,
        .i_parallel,
        .i_serial,
        .o_parallel,
        .o_serial
    );

    // 100 MHz clock
    always #5 i_clk = ~i_clk;

    initial begin
        $dumpfile("shift_register.vcd");
        $dumpvars(0, shift_register_tb);
    end

    initial begin
        $display("Simulation start");
        i_clk = 0;
        i_rst_n = 1;
        i_s0 = 0;
        i_s1 = 0;
        i_oe0 = 1;
        i_oe1 = 0;
        i_parallel = 0;
        i_serial = 0;

        $display("Testing reset");
        test_reset;

        $display("Testing parallel load");
        for (int i = 0; i < 9; i++)
            test_parallel_load($random);

        test_reset;
        $display("Testing right shift");
        i_oe0 = 0;
        i_oe1 = 0;
        test_shift_right($random);

        test_reset;
        $display("Testing left shift");
        i_oe0 = 0;
        i_oe1 = 0;
        test_shift_left($random);

        $display("Testing output modes (check waveform)");
        i_s0 = 0;
        i_s1 = 0;

        // High impedance on
        @(negedge i_clk) begin
            i_oe0 = 1;
            i_oe1 = 1;
        end

        // High impedance off
        @(negedge i_clk) begin
            i_oe0 = 1;
            i_oe1 = 0;
        end

        // Low output on
        @(negedge i_clk) begin
            i_oe0 = 0;
            i_oe1 = 1;
        end

        // Low output off
        @(negedge i_clk) begin
            i_oe0 = 0;
            i_oe1 = 0;
        end
    
        @(negedge i_clk);
        
        $display("Simulation complete");
        $finish;
    end

    task test_reset;
        repeat (16) @(negedge i_clk)
            i_rst_n = 0;

        @(negedge i_clk) begin
            assert(o_parallel == 'b0 && o_serial == 'b0) else
            $fatal(1, "Reset failed");

            i_rst_n = 1;
        end
    endtask

    task test_parallel_load;
        input [7:0] data;

        @(negedge i_clk) begin
            i_s0 = 1;
            i_s1 = 1;
            i_oe1 = 0;
            i_parallel = data;
        end

        @(negedge i_clk)
            i_s0 = 0;
            i_s1 = 0;

            assert(o_parallel == data && o_serial == 'b0) else
            $fatal(1, "Parallel load failed");
    endtask

    task test_shift_right;
        reg [7:0] prev_data;
        reg [7:0] data;

        data = 'b0;
        for (int i = 0; i < 9; i++) begin
            // Disable output
            i_oe1 = 0;

            prev_data = data;
            data = $random;

            for (int j = 0; j < 8; j++) begin
                i_s0 = 1;
                i_s1 = 0;

                @(negedge i_clk) begin
                    i_serial = data[j];
                end

                @(posedge i_clk)
                    assert(o_serial == prev_data[j]) else
                    $fatal(1, "Right shift (serial) failed");
            end

            @(negedge i_clk) begin
                // Hold
                i_s0 = 0;
                i_s1 = 0;
            end

            @(negedge i_clk) begin
                assert(o_parallel == data) else
                $fatal(1, "Right shift failed");
            end
        end
    endtask

    task test_shift_left;
        reg [7:0] prev_data;
        reg [7:0] data;

        data = 'b0;
        for (int i = 0; i < 9; i++) begin
            // Disable output
            i_oe1 = 0;

            prev_data = data;
            data = $random;

            for (int j = 0; j < 8; j++) begin
                i_s0 = 0;
                i_s1 = 1;

                @(negedge i_clk) begin
                    i_serial = data[j];
                end

                @(posedge i_clk);
                    assert(o_serial == prev_data[j]) else
                    $fatal(1, "Left shift (serial) failed");
            end

            @(negedge i_clk) begin
                // Hold
                i_s0 = 0;
                i_s1 = 0;
            end

            @(negedge i_clk) begin
                assert(o_parallel == {data[0], data[1],
                                      data[2], data[3],
                                      data[4], data[5],
                                      data[6], data[7]    
                                      }) else
                $fatal(1, "Left shift failed");
            end
        end
    endtask
endmodule