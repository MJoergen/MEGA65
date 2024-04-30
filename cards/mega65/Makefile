XILINX_DIR = /opt/Xilinx/Vivado/2023.1

PROJECT = cards

SRCS  = $(PROJECT)_mega65.vhd
SRCS += disp_cards.vhd
SRCS += bitmap_pkg.vhd
SRCS += ../$(PROJECT).vhd
SRCS += ../../common/clk.vhd
SRCS += ../../common/uart.vhd
SRCS += ../../common/mega65.vhd
SRCS += ../../common/m2m_keyb.vhd
SRCS += ../../common/matrix_to_keynum.vhd
SRCS += ../../common/mega65kbd_to_matrix.vhd
SRCS += ../../common/kb_matrix_ram.vhd
SRCS += ../../common/video_sync.vhd
SRCS += ../../common/video_modes_pkg.vhd

XDC = ../../common/mega65.xdc

$(PROJECT)_mega65.bit: $(PROJECT)_mega65.tcl $(SRCS) $(XDC) Makefile
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

$(PROJECT)_mega65.tcl: Makefile
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRCS) }" >> $@
	echo "read_xdc $(XDC)" >> $@
	echo "set_property XPM_LIBRARIES {XPM_CDC} [current_project]" >> $@
	echo "synth_design -top $(PROJECT)_mega65 -part xc7a200tfbg484-2 -flatten_hierarchy none" >> $@
	echo "write_checkpoint -force post_synth.dcp" >> $@
	echo "source ../../common/debug.tcl" >> $@
	echo "opt_design" >> $@
	echo "place_design" >> $@
	echo "phys_opt_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force $(PROJECT)_mega65.dcp" >> $@
	echo "write_bitstream -force $(PROJECT)_mega65.bit" >> $@
	echo "exit" >> $@

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf post_synth.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf debug.ltx
	rm -rf $(PROJECT)_mega65.tcl
	rm -rf $(PROJECT)_mega65.bit
	rm -rf $(PROJECT)_mega65.dcp
	rm -rf $(PROJECT)_mega65.cache
	rm -rf $(PROJECT)_mega65.hw
	rm -rf $(PROJECT)_mega65.runs
	rm -rf $(PROJECT)_mega65.srcs

