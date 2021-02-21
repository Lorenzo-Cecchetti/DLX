remove_design -all
set files {{"01 - REG_GEN.vhd"} {"02 - MY_PACKAGE.vhd"} {"03 - LOG2.vhd"} {"04 - REG1.vhd"} {"a.a - CU.vhd"} 
			{"a.b.c.a - ADDER_PC.vhd"} {"a.b.c.b - BTB.vhd"} {"a.b.d.a - ADD_SUB.vhd"} {"a.b.d.b - DECODE_IMM_EXT.vhd"} {"a.b.d.c - HAZARD_UNIT.vhd"} 
			{"a.b.d.d - JUMP_COMPARATOR.vhd"} {"a.b.d.e - RF_DECODER.vhd"} {"a.b.d.f - STACK.vhd"} {"a.b.d.g - WRF.vhd"} {"a.b.e.a.a.a - nand4.vhd"} 
			{"a.b.e.a.a.a - nand3.vhd"} {"a.b.e.a.a - LOGICAL.vhd"} {"a.b.e.a.b.c - pg_network_gen.vhd"} {"a.b.e.a.b.c - g_block.vhd"} {"a.b.e.a.b.c - pg_block.vhd"} 
			{"a.b.e.a.b.c - csb_ovf_gen.vhd"} {"a.b.e.a.b.c - csb_gen.vhd"} {"a.b.e.a.b.c - P4_carry_gen.vhd"} {"a.b.e.a.b.c - P4_SUM_GEN.vhd"} {"a.b.e.a.b - P4_ADDER.vhd"} 
			{"a.b.e.a.d.a - mux_encoded.vhd"} {"a.b.e.a.d.a - adder.vhd"} {"a.b.e.a.d - MUL_8.vhd"} {"a.b.e.a.f - SHIFTER.vhd"} {"a.b.e.a.c - COMPARATOR.vhd"} 
			{"a.b.e.a - ALU.vhd"} {"a.b.e.b - FWU.vhd"} {"a.b.f - LHU.vhd"} {"a.b - DATAPATH.vhd"} {"a - DLX.vhd"}}
foreach file $files {
	analyze -library WORK -format VHDL $file
}
elaborate DLX -architecture STRUCTURAL -library WORK
create_clock -name "CLK" -period 2.3 CLK
set_max_delay -from [all_inputs] -to [all_outputs] 2.3
set_clock_gating_style -minimum_bitwidth 1 -max_fanout 1024 -positive_edge_logic {latch and} -control_point before
compile -exact_map -gate_clock
report_timing > DLX_timing.txt
report_power > DLX_power.txt
report_area > DLX_area.txt
report_clock_gating > DLX_clock_gating.txt
write -hierarchy -format verilog -output /home/ms20.3/DLX_SYN/DLX_2_3.v

