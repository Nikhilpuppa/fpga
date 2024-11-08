set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports stage_result]
set_property PACKAGE_PIN W5 [get_ports clk]
set_property PACKAGE_PIN R2 [get_ports reset]
set_property PACKAGE_PIN P3 [get_ports stage_result]


create_clock -period 4.250 -name clk_nik -waveform {0.000 2.125} -add
create_clock -period 4.250 -name clk_nik -waveform {0.000 2.125} [get_ports clk]
