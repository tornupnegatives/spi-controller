COMPILER=iverilog
SIM=vvp

test-all: test-clock test-spi-controller

test-shift-register:
	$(COMPILER) -g2012 -o test_shift_register rtl/shift_register.v sim/shift_register_tb.sv
	$(SIM) ./test_shift_register
	rm -f test_shift_register

test-clock:
	$(COMPILER) -g2012 -o test_clock rtl/clock_divider.v sim/clock_divider_tb.sv
	$(SIM) ./test_clock
	rm -f test_clock

test-spi-controller:
	$(COMPILER) -g2012 -o test_spi_controller sim/spi_controller_tb.sv rtl/shift_register.v rtl/spi_controller.v 
	$(SIM) ./test_spi_controller
	rm -f test_spi_controller
	
clean:
	rm -f *.vcd