COMPILER=iverilog
CFLAGS=-g2012 -Wall
SIM=vvp

test-all: test-clock test-spi-controller

test-shift-register:
	$(COMPILER) $(CFLAGS) -o test_shift_register rtl/shift_register.v sim/shift_register_tb.sv
	$(SIM) ./test_shift_register
	rm -f test_shift_register

test-clock:
	$(COMPILER) $(CFLAGS) -o test_clock rtl/clock_divider.v sim/clock_divider_tb.sv
	$(SIM) ./test_clock
	rm -f test_clock

test-edge-detector:
	$(COMPILER) $(CFLAGS) -o test_edge_detector rtl/edge_detector.v sim/edge_detector_tb.sv
	$(SIM) ./test_edge_detector
	rm -f test_edge_detector

test-spi-controller:
	$(COMPILER) $(CFLAGS) -o test_spi_controller sim/spi_controller_tb.sv rtl/clock_divider.v rtl/spi_controller.v 
	$(SIM) ./test_spi_controller
	rm -f test_spi_controller
	
clean:
	rm -f *.vcd