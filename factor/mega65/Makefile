XILINX_DIR = /opt/Xilinx/Vivado/2023.1

PROJECT = factor
PLATFORM = mega65r6

TOP = $(PROJECT)_$(PLATFORM)

SRCS += ../../common/axi_merger.vhd
SRCS += ../../common/clk.vhd
SRCS += ../../common/math/add_mult.vhd
SRCS += ../../common/math/amm.vhd
SRCS += ../../common/math/cf.vhd
SRCS += ../../common/math/divexact.vhd
SRCS += ../../common/math/divmod.vhd
SRCS += ../../common/math/divexp.vhd
SRCS += ../../common/math/factor_vect.vhd
SRCS += ../../common/math/gcd.vhd
SRCS += ../../common/math/primes.vhd
SRCS += ../../common/math/sqrt.vhd
SRCS += ../../common/kb_matrix_ram.vhd
SRCS += ../../common/m2m_keyb.vhd
SRCS += ../../common/matrix_to_keynum.vhd
SRCS += ../../common/mega65kbd_to_matrix.vhd
SRCS += ../../common/mega65.vhd
SRCS += ../../common/merginator.vhd
SRCS += ../../common/serializer.vhd
SRCS += ../../common/slv_to_dec.vhd
SRCS += ../../common/uart.vhd
SRCS += ../../common/video_modes_pkg.vhd
SRCS += ../../common/video_sync.vhd
SRCS += ../$(PROJECT).vhd
SRCS += ../$(PROJECT)_wrapper.vhd
SRCS += $(TOP).vhd

VAL_DATA_SIZE = 32
VAL_VECTOR_SIZE = 8

GENERICS += -generic G_DATA_SIZE=$(VAL_DATA_SIZE) -generic G_VECTOR_SIZE=$(VAL_VECTOR_SIZE)

XDC = ../../common/$(PLATFORM).xdc

$(TOP).bit: $(TOP).tcl $(SRCS) $(XDC) Makefile
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

$(TOP).tcl: Makefile
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRCS) }" >> $@
	echo "read_xdc $(XDC)" >> $@
	echo "set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]" >> $@
	echo "synth_design -top $(TOP) -part xc7a200tfbg484-2 -flatten_hierarchy none $(GENERICS)" >> $@
	echo "write_checkpoint -force post_synth.dcp" >> $@
	echo "source ../../common/debug.tcl" >> $@
	echo "opt_design" >> $@
	echo "place_design" >> $@
	echo "phys_opt_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force $(TOP).dcp" >> $@
	echo "write_bitstream -force $(TOP).bit" >> $@
	echo "exit" >> $@

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf post_synth.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf debug.ltx
	rm -rf $(TOP).tcl
	rm -rf $(TOP).bit
	rm -rf $(TOP).dcp
	rm -rf $(TOP).cache
	rm -rf $(TOP).hw
	rm -rf $(TOP).runs
	rm -rf $(TOP).srcs

