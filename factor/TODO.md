#Optimizations

1. In divmod.vhd, state SHIFT_ST, use the function leading_index (from gf2_solver) on both
   inputs to determine the amount to shift.

2. In factor_vect.vhd, reduce the amount of time (20%) that divexp is idle.

