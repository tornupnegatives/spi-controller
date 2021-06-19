`timescale 1ns/1ps

module shift_register_tb;
    reg i_clk;
    reg i_rst_n;
    reg i_output_enable_n;
    reg i_latch;
    reg i_serial_in;
    wire [7:0] o_parallel_out;
    wire o_serial_out;

    shift_register DUT
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_output_enable_n(i_output_enable_n),
        .i_latch(i_latch),
        .i_serial_in(i_serial_in),
        .o_parallel_out(o_parallel_out),
        .o_serial_out(o_serial_out)
    );

    // 40 MHz clock (MHz)
    always #12.5 i_clk = ~i_clk;

    // Waveform generator
    initial begin
        $dumpfile("shift_register.vcd");
        $dumpvars(0, shift_register_tb);
    end

    // Simulation
    initial begin
        $display("Simulation start");

        // Initial values
        i_clk = 0;
        i_rst_n = 0;
        i_output_enable_n = 1;
        i_latch = 0;
        i_serial_in = 0;

        // Reset
        repeat (8) @(negedge i_clk) i_rst_n = 0;
        repeat (8) @(negedge i_clk) i_rst_n = 1;

        i_output_enable_n = 0;

        shift(1);
        repeat (8) @(negedge i_clk);

        shift(5);
        repeat (8) @(negedge i_clk);

        shift(99);
        shift(107);
        shift(6);
        shift(43);

        $display("Simulation complete");
        $finish;
    end

    task shift;
        input [7:0] data;
        begin
            for(integer i = 0; i < 8; i = i + 1) begin
                @(negedge i_clk)
                i_serial_in = data[i];
            end
            
            @(negedge i_clk) begin
                i_serial_in = 0;
                i_latch = 1;
            end

            @(negedge i_clk)
                i_latch = 0;
            
            if (o_parallel_out != data) begin
                $display("ERROR: Incorrect value on parallel out");
                $finish;
            end
        end
    endtask
endmodule