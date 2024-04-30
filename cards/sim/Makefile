# This Makefile is used for simulation testing of the module LIFE.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2023.1

PROJECT = cards

TB       = tb_$(PROJECT)
SOURCES  = ../$(PROJECT).vhd

SOURCES += $(TB).vhd
SAVE     = $(TB).gtkw
WAVE     = $(TB).ghw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SOURCES)
	ghdl -i --std=08 -frelaxed-rules -fsynopsys $(SOURCES)
	ghdl -m --std=08 -frelaxed-rules -fsynopsys $(TB)
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) --wave=$(WAVE) --stop-time=100us

$WAVE): sim

show: $(WAVE) $(SAVE)
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

