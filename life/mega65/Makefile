XILINX_DIR = /opt/Xilinx/Vivado/2023.1

SRCS  = life_mega65.vhd
SRCS += clk.vhd
SRCS += controller.vhd
SRCS += uart.vhd
SRCS += ../life.vhd
SRCS += mega65.vhd
SRCS += m2m_keyb.vhd
SRCS += matrix_to_keynum.vhdl
SRCS += mega65kbd_to_matrix.vhdl
SRCS += kb_matrix_ram.vhdl
SRCS += video.vhd
SRCS += video_sync.vhd
SRCS += video_modes_pkg.vhd
SRCS += digits.vhd
SRCS += font.vhd

life_mega65.bit: life_mega65.tcl $(SRCS) mega65.xdc Makefile
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

life_mega65.tcl: Makefile
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRCS) }" >> $@
	echo "read_xdc mega65.xdc" >> $@
	echo "set_property XPM_LIBRARIES {XPM_CDC} [current_project]" >> $@
	echo "synth_design -top life_mega65 -part xc7a200tfbg484-2 -flatten_hierarchy none" >> $@
	echo "write_checkpoint -force post_synth.dcp" >> $@
	echo "source debug.tcl" >> $@
	echo "opt_design" >> $@
	echo "place_design" >> $@
	echo "phys_opt_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force life_mega65.dcp" >> $@
	echo "write_bitstream -force life_mega65.bit" >> $@
	echo "exit" >> $@

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf life_mega65.tcl
	rm -rf life_mega65.bit
	rm -rf life_mega65.dcp
	rm -rf post_synth.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf debug.ltx
	rm -rf life_mega65.cache
	rm -rf life_mega65.hw
	rm -rf life_mega65.runs
	rm -rf life_mega65.srcs

