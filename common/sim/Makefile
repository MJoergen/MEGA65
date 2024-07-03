# This Makefile is used for simulation testing of the module LIFE.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

#PROJECT = add_mult
#PROJECT = amm
#PROJECT = cf
#PROJECT = divexact
#PROJECT = divexp
PROJECT = divmod
#PROJECT = factor_vect
#PROJECT = gcd
#PROJECT = gf2_solver
#PROJECT = jacobi
#PROJECT = primes
#PROJECT = slv_to_dec
#PROJECT = sqrt
#PROJECT = uart

TB       = tb_$(PROJECT)
SOURCES += ../../common/lfsr.vhd
SOURCES += ../../common/ram.vhd
SOURCES += ../../common/slv_to_dec.vhd
SOURCES += ../../common/uart.vhd
SOURCES += ../../common/math/divexact.vhd
SOURCES += ../../common/math/gcd.vhd
SOURCES += ../../common/math/divmod.vhd
SOURCES += ../../common/math/jacobi.vhd
SOURCES += ../../common/math/sqrt.vhd
SOURCES += ../../common/math/divexp.vhd
SOURCES += ../../common/math/amm.vhd
SOURCES += ../../common/math/add_mult.vhd
SOURCES += ../../common/math/cf.vhd
SOURCES += ../../common/math/primes.vhd
SOURCES += ../../common/math/factor_vect.vhd
SOURCES += ../../common/math/gf2_solver.vhd
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
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) --wave=$(WAVE) --stop-time=200us


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

