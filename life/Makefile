project = life
top_module = life_top
sources  = life_top.vhd # Top level
sources += life_pkg.vhd
sources += counter.vhd
sources += life.vhd
sources += vga_controller_640_60.vhd
sources += disp_cells.vhd
sources += MouseRefComp.vhd
sources += mouse_controller.vhd 
sources += mouse_displayer.vhd 
sources += ps2interface.vhd 
sources += resolution_mouse_informer.vhd
sources += eppmodule.vhd

# Simulation
testbench  = $(top_module)_tb
tb_sources = $(testbench).vhd
wave       = $(top_module).ghw
wavesave   = $(top_module).gtkw
unisim_lib = unisim-obj93.cf
stoptime   = --stop-time=10us

# Synthesis
vendor     = xilinx
family     = spartan3e
part       = xc3s250e-5-cp132
vfiles     = $(sources)
board      = Basys2
index      = 0

# Host PC application
app_source = $(project).cpp
app_bin    = ~/bin/$(project)
app_libs   = -ldmgr -ldepp

include ../xilinx/xilinx.mk

