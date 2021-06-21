///////////////////////////////////////////////////////////////////////////////
// Module Name:     Clock Divider
// Target Devices:  Xilinx Artix-7
// Description:     Simple clock divider based on a counter
//                  f_output = f_input / div
//
// Notes:
///////////////////////////////////////////////////////////////////////////////

module clock_divider
    (
        // FPGA interface
        input i_clk,            // Fast FPGA clock
        input i_rst_n,          // Active low reset

        input [31:0] i_div,     // Number of FPGA clock cycles per clock slock
        output reg o_clk        // Slow clock
    );

    reg [31:0] r_div;
    reg [31:0] r_count;

    // Register div to change clock frequency
    always @(posedge i_clk) begin
        // Use default value on reset
        if (!i_rst_n)
            r_div <= 2;
        
        else
            r_div <= i_div;
    end

    // Generate slow clock
    always @(posedge i_clk) begin
        // Idle clock when reset low
        if (!i_rst_n) begin
            r_count <= 0;
            o_clk <= 0;
        end

        else begin
            r_count <= r_count + 1;

            if (r_count == r_div) begin
                r_count <= 0;
                o_clk <= 1;
            end

            else
                o_clk <= 0;
        end
    end
endmodule