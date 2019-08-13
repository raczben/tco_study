# Clock and reset
set_property PACKAGE_PIN  AB30 [get_ports i_clk_p]
set_property IOSTANDARD   LVDS [get_ports i_clk_p]
set_property PACKAGE_PIN  AJ9  [get_ports i_rst]
set_property IOSTANDARD LVCMOS18 [get_ports i_rst]

# Place all test output
set_property PACKAGE_PIN  W33  [get_ports o_native_mc_p ]
set_property PACKAGE_PIN  AC33 [get_ports o_iob_shifted_clk_p ]
set_property PACKAGE_PIN  AA34 [get_ports o_odelay_p          ]
set_property PACKAGE_PIN  AA29 [get_ports o_odelay_nclk_p    ]

# All output port is LVDS
set_property IOSTANDARD   LVDS [get_ports o_*_p]

# Place all IOB style output to IOB
set_property IOB          TRUE [get_cells q_iob*d2_reg]
