## MEGA65 pin mapping
#
################################
## TIMING CONSTRAINTS
################################

## System board clock (100 MHz)
create_clock -period 10.000 -name clk_mega65 [get_ports {sys_clk_i}]

## Name Autogenerated Clocks
create_generated_clock -name clk     [get_pins mega65_inst/clk_inst/pll_inst/CLKOUT0];          # 100 MHz
create_generated_clock -name vga_clk [get_pins mega65_inst/clk_inst/mmcm_vga_inst/CLKOUT0];     # 74.25 MHz

################################
## Pin to signal mapping
################################

# Onboard crystal oscillator = 100 MHz
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33} [get_ports {sys_clk_i}];              # CLOCK_FPGA_MRCC

# MAX10 FPGA (delivers reset)
set_property -dict {PACKAGE_PIN M13  IOSTANDARD LVCMOS33} [get_ports {sys_rstn_i}];             # FPGA_RESET_N

# USB-RS232 Interface
set_property -dict {PACKAGE_PIN L14  IOSTANDARD LVCMOS33} [get_ports {uart_rxd_i}];             # DBG_UART_RX
set_property -dict {PACKAGE_PIN L13  IOSTANDARD LVCMOS33} [get_ports {uart_txd_o}];             # DBG_UART_TX

# VGA via VDAC. U3 = ADV7125BCPZ170
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports {vdac_blank_n_o}];         # VDAC_BLANK_N
set_property -dict {PACKAGE_PIN AA9  IOSTANDARD LVCMOS33} [get_ports {vdac_clk_o}];             # VDAC_CLK
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {vdac_sync_n_o}];          # VDAC_SYNC_N
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[0]}];          # B0
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[1]}];          # B1
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[2]}];          # B2
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[3]}];          # B3
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[4]}];          # B4
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[5]}];          # B5
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[6]}];          # B6
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[7]}];          # B7
set_property -dict {PACKAGE_PIN Y14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[0]}];         # G0
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[1]}];         # G1
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[2]}];         # G2
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[3]}];         # G3
set_property -dict {PACKAGE_PIN Y13  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[4]}];         # G4
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[5]}];         # G5
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[6]}];         # G6
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[7]}];         # G7
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports {vga_hs_o}];               # HSYNC
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[0]}];           # R0
set_property -dict {PACKAGE_PIN V15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[1]}];           # R1
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[2]}];           # R2
set_property -dict {PACKAGE_PIN Y17  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[3]}];           # R3
set_property -dict {PACKAGE_PIN Y16  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[4]}];           # R4
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[5]}];           # R5
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[6]}];           # R6
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[7]}];           # R7
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports {vga_vs_o}];               # VSYNC

# MEGA65 Keyboard
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33} [get_ports {kb_io0_o}];               # KB_IO1
set_property -dict {PACKAGE_PIN A13  IOSTANDARD LVCMOS33} [get_ports {kb_io1_o}];               # KB_IO2
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33} [get_ports {kb_io2_i}];               # KB_IO3

# Place KBD close to I/O pins
startgroup
create_pblock pblock_i_kbd
resize_pblock pblock_i_kbd -add {SLICE_X0Y225:SLICE_X7Y237}
add_cells_to_pblock pblock_i_kbd [get_cells [list mega65_inst/m2m_keyb_inst/m65driver]]
endgroup


################################
## CONFIGURATION AND BITSTREAM PROPERTIES
################################

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]

