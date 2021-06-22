`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Module Name:     Shift Register
// Engineer:        Joseph Bellahcen <josbella@iu.edu>
// Target Devices:  Xilinx Artix-7
// Description:     Universal 8-bit shift register
//                  Optional tri-state output
//
// Notes:           Maximum frequency: 40 MHz
///////////////////////////////////////////////////////////////////////////////

module shift_register
    (
        // FPGA interface
        input i_clk,
        input i_rst_n,

        // Control interface
        // ┌───────┬────┬────┬────────────────────┐
        // │ RESET │ S0 │ S1 │      Behavior      │
        // ├───────┼────┼────┼────────────────────┤
        // │ L     │ X  │ X  │ Asynchronous reset │
        // │ H     │ H  │ H  │ Parallel load      │
        // │ H     │ L  │ H  │ Left shift         │
        // │ H     │ H  │ L  │ Right shift        │
        // │ H     │ L  │ L  │ Hold               │
        // └───────┴────┴────┴────────────────────┘
        input i_s0,
        input i_s1,

        // Tri-state output enable
        // ┌─────┬─────┬─────────────────────────────┐
        // │ OE0 │ OE1 │         Behavior            │
        // ├─────┼─────┼─────────────────────────────┤
        // │ H   │ X   │ High-impedance off state    │
        // │ L   │ X   │ Low off state               │
        // │ X   │ H   │ Output disabled             │
        // │ X   │ L   │ Output enabled              │
        // └─────┴─────┴─────────────────────────────┘
        input i_oe0,
        input i_oe1,

        // IO interface
        input [7:0]         i_parallel,
        input               i_serial,
        output reg [7:0]    o_parallel,
        output reg          o_serial
    );

    reg [7:0] r_data;
    reg       r_overflow;

    // Input
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            r_data <= 'b0;
            r_overflow <= 'b0;
        end

        else begin
            case ({i_s0, i_s1})
                'b00: begin
                    r_data <= r_data;
                    r_overflow <= r_overflow;
                end

                'b01: begin
                    r_data <= {r_data[6:0], i_serial};
                    r_overflow <= r_data[7];
                end

                'b10: begin
                    r_data <= {i_serial, r_data[7:1]};
                    r_overflow <= r_data[0];
                end

                'b11: begin
                    r_data <= i_parallel;
                    r_overflow <= 'b0;
                end
            endcase
        end
    end

    // Output
    always @(*) begin
        if (~i_rst_n) begin
            o_parallel = 'b0;
            o_serial = 'b0;
        end

        // Output enabled
        else if (~i_oe1) begin
            o_parallel = r_data;
            o_serial = r_overflow;
        end

        // Output disabled
        else begin
            o_parallel = i_oe0 ? 'bz : 'b0;
            o_serial = i_oe0   ? 'bz : 'b0;
        end
    end
endmodule