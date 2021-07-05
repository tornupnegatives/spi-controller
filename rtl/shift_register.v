`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Module Name:     Shift Register
// Engineer:        Joseph Bellahcen <josbella@iu.edu>
// Target Devices:  Xilinx Artix-7
// Description:     Universal 8-bit shift register
//
// Notes:           Maximum frequency: 40 MHz
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
        // Controls serial IO
        input       i_slow_clk,

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

    // State machine
    reg [2:0] r_state;
    reg [2:0] r_next_state;

    // Shift and output registers
    reg [7:0]   r_data;
    reg [7:0]   r_output;

    // State machine logic
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n)
            r_state <= RESET;
        
        else if (i_mode)
            r_state <= i_mode;
        
        else
            r_state <= r_next_state;
    end

    always @(*) begin
        // Defaults
        r_output = 0;
        r_next_state = r_state;
        o_serial = 0;
        o_parallel = 0;

        case (r_state)
            RESET: begin 
                o_serial = 0;
                o_parallel = 0;
                r_data = 0;
                r_next_state = HOLD;
            end

            PARALLEL_LOAD: begin
                r_data = i_parallel;
                r_next_state = HOLD;
            end

            LEFT_SHIFT: begin
                if (i_slow_clk) begin
                    o_serial = r_data[7];
                    r_data = {r_data[6:0], i_serial};
                    
                end

                r_next_state = HOLD;
            end

            RIGHT_SHIFT: begin
                if (i_slow_clk) begin
                    o_serial = r_data[0];
                    r_data = {i_serial, r_data[7:1]};
                end

                r_next_state = HOLD;
            end
        endcase

        // Asynchronous output enable
        if (~i_output_enable_n)
            o_parallel = r_data;
    end
endmodule