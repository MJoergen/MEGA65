project = timer_demo
top_module = timer_demo
sources  = timer_demo.vhd # Top level
sources += vga_controller_640_60.vhd
sources += disp_background.vhd
sources += timer.vhd
sources += bitmap_pkg.vhd
sources += bitmap.vhd

testbench = $(top_module)_tb
tb_sources = $(testbench).vhd
wave = $(top_module).ghw
wavesave = $(top_module).gtkw
unisim_lib = unisim-obj93.cf
vfiles = $(sources)

unisims = /opt/Xilinx/14.4/ISE_DS/ISE/vhdl/src/unisims

vendor = xilinx
family = spartan3e
part   = xc3s250e-5-cp132

sim: $(wave)
	gtkwave $(wave) $(wavesave)

$(wave): $(testbench)
	-ghdl -r $(testbench) --assert-level=error --wave=$(wave) --stop-time=3000ns

$(testbench): $(testbench).o $(unisim_lib) $(sources) $(tb_sources)
	ghdl -m --ieee=synopsys -fexplicit $(testbench)

$(unisim_lib):
	ghdl -i --work=unisim $(unisims)/*vhd
	ghdl -i --work=unisim $(unisims)/primitive/*vhd
	
$(testbench).o: $(sources) $(tb_sources)
	ghdl -i --work=work $(sources) $(tb_sources)

clean::
	rm -f *.o *.cf $(testbench) $(wave) $(top_module)

include ../xilinx/xilinx.mk

