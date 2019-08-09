
# create a 100MHz clock
create_clock -period 10.000 [get_ports i_clk_p]

#create the associated virtual input clock
create_clock -name clkB_virt -period 10

#create the input delay referencing the virtual clock
#specify the maximum external clock delay from the global oscillator towards the FPGA
set CLK_fpga_m 3.5
set CLK_fpga_M 4
#specify the maximum external clock delay from the global oscillator towards the DAQ module
set CLK_daq_m 5
set CLK_daq_M 6.5
#specify the maximum setup and minimum hold time of the DAQ module
set tSUb 2
set tHb 0.5
#Board delay from FPGA to DAQ module (on trigger)
set BD_trigger_m 6.5
set BD_trigger_M 7.0

# odelay_M = 8.0
# odelay_m = 3.0
set odelay_M [expr $CLK_fpga_M + $tSUb + $BD_trigger_M - $CLK_daq_m]
set odelay_m [expr $CLK_fpga_m - $tHb  + $BD_trigger_m - $CLK_daq_M]

#create the output maximum delay for the data output from the
#FPGA that accounts for all delays specified (tSUb + 6.045)
set_output_delay -clock clkB_virt -max [expr $odelay_M] [get_ports {o_native* o_iob*}]
set_output_delay -clock clkB_virt -max [expr $odelay_M -5] [get_ports {o_ddr*}]
#create the output minimum delay for the data output from the
#FPGA that accounts for all delays specified (tHb + 3.992)
set_output_delay -clock clkB_virt -min [expr $odelay_m] [get_ports {o_native* o_iob*}]
set_output_delay -clock clkB_virt -min [expr $odelay_m] [get_ports {o_ddr*}]

# reset
set_input_delay -clock clkB_virt 1 [get_ports i_rst]
