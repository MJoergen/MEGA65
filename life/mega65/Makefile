XILINX_DIR = /opt/Xilinx/Vivado/2023.1

SRCS  = life_mega65.vhd
SRCS += controller.vhd
SRCS += digits.vhd
SRCS += ../life.vhd
SRCS += ../../common/clk.vhd
SRCS += ../../common/uart.vhd
SRCS += ../../common/mega65.vhd
SRCS += ../../common/m2m_keyb.vhd
SRCS += ../../common/matrix_to_keynum.vhd
SRCS += ../../common/mega65kbd_to_matrix.vhd
SRCS += ../../common/kb_matrix_ram.vhd
SRCS += ../../common/video.vhd
SRCS += ../../common/video_sync.vhd
SRCS += ../../common/video_modes_pkg.vhd
SRCS += ../../common/font.vhd

XDC = ../../common/mega65.xdc

life_mega65.bit: life_mega65.tcl $(SRCS) $(XDC) Makefile
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

life_mega65.tcl: Makefile
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRCS) }" >> $@
	echo "read_xdc $(XDC)" >> $@
	echo "set_property XPM_LIBRARIES {XPM_CDC} [current_project]" >> $@
	echo "synth_design -top life_mega65 -part xc7a200tfbg484-2 -flatten_hierarchy none" >> $@
	echo "write_checkpoint -force post_synth.dcp" >> $@
	echo "source ../../common/debug.tcl" >> $@
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

