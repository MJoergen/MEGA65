# This Makefile is used for simulation testing of the module LIFE.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2023.1
XPM_DIR = ../../../../fransschreuder/xpm_vhdl

PROJECT = timer

TB       = tb_$(PROJECT)
#TB       = tb_$(PROJECT)_wrapper
SOURCES  = ../../common/uart.vhd
SOURCES += ../../common/clk.vhd
SOURCES += ../../common/serializer.vhd
SOURCES += ../../common/mega65.vhd
SOURCES += ../../common/m2m_keyb.vhd
SOURCES += ../../common/matrix_to_keynum.vhd
SOURCES += ../../common/mega65kbd_to_matrix.vhd
SOURCES += ../../common/kb_matrix_ram.vhd
SOURCES += ../../common/video_sync.vhd
SOURCES += ../../common/video_modes_pkg.vhd
SOURCES += ../../common/font.vhd
SOURCES += ../$(PROJECT).vhd
SOURCES += ../$(PROJECT)_wrapper.vhd
SOURCES += ../disp_background.vhd
SOURCES += ../bitmap.vhd
SOURCES += ../bitmap_pkg.vhd
SOURCES += $(TB).vhd
SAVE     = $(TB).gtkw
WAVE     = $(TB).ghw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SOURCES) unisim-obj08.cf xpm-obj08.cf
	ghdl -i --std=08 -frelaxed-rules -fsynopsys $(SOURCES)
	ghdl -m --std=08 -frelaxed-rules -fsynopsys $(TB)
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) --wave=$(WAVE) --stop-time=100us

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

