COMPILER=iverilog
SIM=vvp

test-all: test-clock test-spi-controller

test-shift-register:
	$(COMPILER) -o test_shift_register rtl/shift_register.v sim/shift_register_tb.v
	$(SIM) ./test_shift_register
	rm -f test_shift_register

test-clock:
	$(COMPILER) -o test_clock rtl/clock_divider.v sim/clock_divider_tb.v
	$(SIM) ./test_clock
	rm -f test_clock

test-spi-controller:
	$(COMPILER) -o test_spi_controller rtl/spi_controller.v sim/spi_controller_tb.v
	$(SIM) ./test_spi_controller
	rm -f test_spi_controller
	
clean:
	rm -f *.vcd