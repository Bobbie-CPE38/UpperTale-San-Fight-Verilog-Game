##-----------------------------------
## Constraints Module
## Digilent Basys 3
## Onboard clock 100MHz
## VGA Resolution: 640x480 @ 60Hz
## Pixel Clock 25MHz
##-----------------------------------
## Clock
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports CLK]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK]
## Use BTNC as Reset Button (active high)
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports RESET]
## VGA Connector
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {RED[0]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {RED[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {RED[2]}]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {RED[3]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {BLUE[0]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {BLUE[1]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {BLUE[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {BLUE[3]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {GREEN[0]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {GREEN[1]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {GREEN[2]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {GREEN[3]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports HSYNC]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports VSYNC]
## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property IOSTANDARD LVCMOS33 [get_ports btn_d]
set_property IOSTANDARD LVCMOS33 [get_ports btn_l]
set_property IOSTANDARD LVCMOS33 [get_ports btn_r]
set_property IOSTANDARD LVCMOS33 [get_ports btn_u]
set_property PACKAGE_PIN W19 [get_ports btn_l]
set_property PACKAGE_PIN T17 [get_ports btn_r]
set_property PACKAGE_PIN T18 [get_ports btn_u]
set_property PACKAGE_PIN U18 [get_ports btn_d]
