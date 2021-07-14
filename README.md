# SPI Controller

Verilog SPI controller implementation which supports a variable clock speed and all four [SPI Modes](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Mode_numbers).

## Configuration

The device is configured using a 10-bit bus as follows:

|Bit # | 10...3 | 2...1 | 0 |
|------|--------|-------|---|
| Description | SPI clock ratio | SPI mode | Store configuration |
|Default value | 0x2 | 0x0 | N/A |
| Note | MSB first | MSB first | Raise for one clock cycle configure device |

The maximum clock ratio is 1:255

## Implementation

This design was implemented on a Xilinx Artix-7 board and runs at 100 MHz

It is intended to run on Skywater's Rad-Hard architecture, and support is ongoing
