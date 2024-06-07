# Type 'make formal' to run formal verification
# Type 'make synth' to run synthesis

DUT  = divmod
DUT  = jacobi
#DUT  = divexact
#DUT  = slv_to_dec
#DUT  = gcd
#DUT  = uart
#DUT  = merginator
#DUT  = axi_merger
#DUT  = serializer

#SRC += ../divexact.vhd
SRC += ../divmod.vhd
SRC += ../$(DUT).vhd

#GENERICS = -gG_DATA_SIZE_IN=32 -gG_DATA_SIZE_OUT=8
GENERICS = -gG_DATA_SIZE=8
#GENERICS = -gG_DIVISOR=8

#######################
# Formal verification
#######################

.PHONY: formal
formal: $(DUT)_cover/PASS $(DUT)_prove/PASS
$(DUT)_cover/PASS: $(DUT).sby $(DUT).psl $(SRC)
	# This is the main command line to run the formal verification
	sby --yosys "yosys -m ghdl" -f $(DUT).sby

show_prove:
	gtkwave $(DUT)_prove/engine_0/trace.vcd $(DUT).gtkw

show_cover3:
	gtkwave $(DUT)_cover/engine_0/trace3.vcd $(DUT).gtkw


#######################
# Synthesis
#######################

.PHONY: synth
synth: work-obj08.cf
	yosys -m ghdl -p 'ghdl -fpsl -fsynopsys --std=08 $(GENERICS) $(DUT); synth_xilinx -top $(DUT) -edif $(DUT).edif' > yosys.log

work-obj08.cf: $(SRC)
	ghdl -a -fpsl -fsynopsys --std=08 $^


#######################
# Cleanup
#######################

.PHONY: clean
clean:
	rm -rf $(DUT)_cover/
	rm -rf $(DUT)_prove/
	rm -rf work-obj08.cf
	rm -rf yosys.log
	rm -rf $(DUT).edif

