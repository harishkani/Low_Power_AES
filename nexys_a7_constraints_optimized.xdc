## Nexys A7-100T Board Constraints for AES FPGA Top Module - OPTIMIZED
## Artix-7 XC7A100T FPGA
## Target: 200 MHz operation for Phase 1 optimizations

## Clock signal (100 MHz input, can be increased with clock wizard if needed)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 5.00 -waveform {0 2.5} [get_ports clk]

## Clock uncertainty and jitter
set_clock_uncertainty -setup 0.2 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.1 [get_clocks sys_clk_pin]

## Input delay constraints (assumes 2ns delay from board traces)
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports {sw[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {sw[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports rst_n]
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports btn*]
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports btn*]

## Output delay constraints (assumes 2ns delay to board traces)
set_output_delay -clock [get_clocks sys_clk_pin] -min -0.5 [get_ports {led[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {led[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min -0.5 [get_ports {seg[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {seg[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -min -0.5 [get_ports {an[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {an[*]}]

## Reset button (active-low) - CPU_RESETN
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports rst_n]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets rst_n_IBUF]

## Buttons (active-high on Nexys A7)
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports btnC]
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports btnR]

## Switches
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports {sw[8]}]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports {sw[9]}]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports {sw[10]}]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports {sw[11]}]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports {sw[12]}]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports {sw[13]}]
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports {sw[14]}]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports {sw[15]}]

## LEDs
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports {led[15]}]

## 7-Segment Display (CA - Common Anode on Nexys A7)
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports {an[3]}]
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports {an[4]}]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports {an[5]}]
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports {an[6]}]
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports {an[7]}]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Bitstream Configuration
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

## Timing constraints for button clocks
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btnC_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btnU_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btnL_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btnR_IBUF]

## False paths for asynchronous inputs (buttons, switches)
set_false_path -from [get_ports {sw[*]}] -to [all_registers]
set_false_path -from [get_ports btn*] -to [all_registers]

## Multi-cycle paths for display controller (slow refresh rate)
set_multicycle_path -setup 2 -to [get_ports {seg[*]}]
set_multicycle_path -hold 1 -to [get_ports {seg[*]}]
set_multicycle_path -setup 2 -to [get_ports {an[*]}]
set_multicycle_path -hold 1 -to [get_ports {an[*]}]

## Optimization directives for high-speed design
set_property OPTIMIZE_FOR_POWER false [get_designs]

## NOTE: For 200 MHz operation from 100 MHz board clock
## You will need to add a Clocking Wizard IP to multiply the clock:
## - Input: 100 MHz (from E3)
## - Output: 200 MHz (to your design)
## - Enable clock feedback and phase alignment
##
## Update create_clock command above to match your actual design clock:
## If using clock wizard output directly at 200 MHz:
## create_clock -add -name sys_clk_pin -period 5.00 -waveform {0 2.5} [get_ports clk]
##
## The current constraint assumes 200 MHz (5ns period).
## If you keep the 100 MHz board clock without clock wizard, change period to 10.00
