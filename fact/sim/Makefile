# This Makefile is used for simulation testing of the module LIFE.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2023.1
XPM_DIR = ../../../../fransschreuder/xpm_vhdl

PROJECT = fact

#TB    = tb_$(PROJECT)
TB    = tb_$(PROJECT)_wrapper
SRCS += ../../common/clk.vhd
SRCS += ../../common/divexact.vhd
SRCS += ../../common/font.vhd
SRCS += ../../common/gcd.vhd
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
SRCS += ../control.vhd
SRCS += $(TB).vhd
SAVE  = $(TB).gtkw
WAVE  = $(TB).ghw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SRCS) unisim-obj08.cf xpm-obj08.cf
	ghdl -i --std=08 -frelaxed-rules -fsynopsys $(SRCS)
	ghdl -m --std=08 -frelaxed-rules -fsynopsys $(TB)
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) $(GENERICS) --wave=$(WAVE) --stop-time=12000us

unisim-obj08.cf:
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd

xpm-obj08.cf:
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_VCOMP.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_single.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_array_single.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_async_rst.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_gray.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_handshake.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_low_latency_handshake.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_pulse.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_sync_rst.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_base.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_dpdistram.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_dprom.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_sdpram.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_spram.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_sprom.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_tdpram.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_rst.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_reg_bit.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_counter_updn.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_reg_vec.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_reg_pipe_bit.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_base.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_async.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axi_reg_slice.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axif.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axil.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axis.vhd
	ghdl -a --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_sync.vhd


$WAVE): sim

show: $(WAVE) $(SAVE)
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf xpm-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

