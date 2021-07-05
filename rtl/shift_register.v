`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     Shift Register
// Engineer:        Joseph Bellahcen <josbella@iu.edu>
// Target Devices:  Xilinx Artix-7
// Description:     Universal 8-bit shift register
///////////////////////////////////////////////////////////////////////////////

// parallel load -> parallel out on serial clock
// serial load on serial clock -> parallel out

module shift_register
    (
        // FPGA interface
        input i_clk,
        input i_rst_n,

        // IO controls
        // ┌───────┬────┬────┬────────────────────┐
        // │ RESET │ M1 │ M0 │      Behavior      │
        // ├───────┼────┼────┼────────────────────┤
        // │ L     │ X  │ X  │ Asynchronous reset │
        // │ H     │ H  │ H  │ Parallel load      │
        // │ H     │ H  │ L  │ Left shift         │
        // │ H     │ L  │ H  │ Right shift        │
        // │ H     │ L  │ L  │ NOP                │
        // └───────┴────┴────┴────────────────────┘
        input [1:0] i_mode,
        // Move internal register to parallel output (async)
        input       i_output_enable_n,

        // IO
        input [7:0]  i_parallel,
        input        i_serial,

        output reg [7:0] o_parallel,
        output reg       o_serial
    );

    // Operational states
    localparam [2:0]
        PARALLEL_LOAD   = 2'b11,
        LEFT_SHIFT      = 2'b10,
        RIGHT_SHIFT     = 2'b01,
        HOLD            = 2'b00,
        RESET           = 3'b100;

    // Shift and output registers
    reg [7:0]   r_parallel;
    reg [7:0]   r_output;
    reg         r_serial;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_parallel <= 0;
            r_serial <= 0;
            r_output <= 0;
        end

        else if (i_mode) begin
            case(i_mode)
                PARALLEL_LOAD: begin
                    r_serial <= 0;
                    r_parallel <= i_parallel;
                end

                LEFT_SHIFT: begin
                    r_serial <= r_parallel[7];
                    r_parallel <= {r_parallel[6:0], i_serial};
                end

                RIGHT_SHIFT: begin
                    r_serial <= r_parallel[0];
                    r_parallel <= {i_serial, r_parallel[7:1]};
                end
            endcase
        end
    end

    always @(*) begin
        o_serial = r_serial;
        o_parallel = 7'h0;

        if (~i_output_enable_n) begin
            o_serial = r_serial;
            o_parallel = r_parallel;
        end
    end
endmodule