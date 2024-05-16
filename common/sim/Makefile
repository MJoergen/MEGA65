# This Makefile is used for simulation testing of the module LIFE.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

PROJECT = uart
PROJECT = gcd
PROJECT = divexact
PROJECT = slv_to_dec

TB       = tb_$(PROJECT)
SOURCES  = ../../common/uart.vhd
SOURCES += ../../common/slv_to_dec.vhd
SOURCES += ../../common/divexact.vhd
SOURCES += ../../common/gcd.vhd
SOURCES += ../../common/lfsr.vhd
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
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) --wave=$(WAVE) --stop-time=4000us


$WAVE): sim

show: $(WAVE)
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
