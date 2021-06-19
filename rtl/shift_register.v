///////////////////////////////////////////////////////////////////////////////
// Module Name:     Shift Register
// Engineer:        Joseph Bellahcen <josbella@iu.edu>
// Target Devices:  Xilinx Artix-7
// Description:     Serial-in, parallel-out, serial-out shift register
//
// Notes:           Maximum frequency: 40 MHz
///////////////////////////////////////////////////////////////////////////////

module shift_register
    #(parameter WORD_SIZE = 8)
    (
        // FPGA interface
        input i_clk,                        // Data is shifted into internal input register on FPGA clock
        input i_rst_n,                      // Clears contents of internal input register ONLY. Active low

        // IO controls
        input i_output_enable_n,            // Releases contents of internal latch. Active low
        input i_latch,                      // Transfers contents of internal input register to internal latch

        // IO
        input i_serial_in,                              // Serial data in. Read on the rising edge of every clock cycle
        output reg [WORD_SIZE-1:0] o_parallel_out,      // Parallel data out shows contents of internal latch if output enable low
        output reg o_serial_out                         // Serial data out. Updated on the rising edge of every clock cycle
    );

    reg [WORD_SIZE-1:0] r_input;
    reg [WORD_SIZE-1:0] r_latch;

    // Serial IO
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_input <= 'b0;
            o_serial_out <= 0;
        end

        else begin
            r_input <= {i_serial_in, r_input[WORD_SIZE-1:1]};
            o_serial_out <= r_input[0];
        end
    end

    // Parallel out (not affected by reset)
    always @(posedge i_clk) begin
        if (i_latch)
            r_latch <= r_input;
    end

    // Asynchronous output enable
    always @(*)
        if (i_output_enable_n)
            o_parallel_out <= 'bz;
        else
            o_parallel_out <= r_latch;
endmodule