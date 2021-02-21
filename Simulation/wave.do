onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /tb/clk_tb
add wave -noupdate -format Logic /tb/rst_tb
add wave -noupdate -divider PC
add wave -noupdate -format Literal -radix unsigned /tb/iram_address_tb
add wave -noupdate -format Literal -radix decimal /tb/dlx_inst/datapath_inst/pc_add4_if_id
add wave -noupdate -divider CU
add wave -noupdate -color {Sky Blue} -format Literal /tb/iram_data_tb
add wave -noupdate -color {Sky Blue} -format Literal /tb/dlx_inst/cu_inst/cw
add wave -noupdate -color {Sky Blue} -format Literal /tb/dlx_inst/cu_inst/id_ex
add wave -noupdate -color {Sky Blue} -format Literal /tb/dlx_inst/cu_inst/ex_mem
add wave -noupdate -color {sky blue} -format Literal /tb/dlx_inst/datapath_inst/ir_id
add wave -noupdate -color {sky blue} -format Literal /tb/dlx_inst/datapath_inst/ir_if_id
add wave -noupdate -divider {REGISTER FILE}
add wave -noupdate -color Cyan -format Literal -radix decimal /tb/dlx_inst/datapath_inst/reg_file/phy_reg
add wave -noupdate -color cyan -format Literal -radix decimal /tb/dlx_inst/datapath_inst/rf_out_1_id
add wave -noupdate -color cyan -format Literal -radix decimal /tb/dlx_inst/datapath_inst/rf_out_1_id_ex
add wave -noupdate -color cyan -format Literal -radix decimal /tb/dlx_inst/datapath_inst/rf_out_2_id
add wave -noupdate -color cyan -format Literal -radix decimal /tb/dlx_inst/datapath_inst/rf_out_2_id_ex
add wave -noupdate -color cyan -format Logic -radix binary /tb/dlx_inst/datapath_inst/reg_file/write_1_en
add wave -noupdate -color cyan -format Logic -radix binary /tb/dlx_inst/datapath_inst/reg_file/write_2_en
add wave -noupdate -color cyan -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/reg_file/read_1_addr
add wave -noupdate -color cyan -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/reg_file/read_2_addr
add wave -noupdate -divider DRAM
add wave -noupdate -format Literal /tb/dram_inst/dram_mem
add wave -noupdate -format Literal -radix unsigned /tb/dram_address_tb
add wave -noupdate -format Literal -radix decimal /tb/dram_data_in_tb
add wave -noupdate -format Literal -radix decimal /tb/dram_data_out_tb
add wave -noupdate -format Logic /tb/dram_enable_tb
add wave -noupdate -format Logic /tb/dram_read_write_n_tb
add wave -noupdate -format Literal /tb/align_check_tb
add wave -noupdate -divider STALL
add wave -noupdate -format Logic /tb/dlx_inst/datapath_inst/stall
add wave -noupdate -divider ALU
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a_add
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a_comp
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a_log
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a_mul
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/a_sh
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b_add
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b_comp
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b_log
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b_mul
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/b_sh
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/o_32
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/o_64
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/o_add
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/o_log
add wave -noupdate -color Orange -format Literal -radix decimal /tb/dlx_inst/datapath_inst/alu_inst/o_sh
add wave -noupdate -divider FWU
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_ex_to_ex_a
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_ex_to_ex_b
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_ex_to_id
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_mem_to_ex_a
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_mem_to_ex_b
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_mem_to_id
add wave -noupdate -color {Pale Green} -format Literal /tb/dlx_inst/datapath_inst/fwu_inst/fw_mem_to_mem
add wave -noupdate -divider RD
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_1_mul_ex_mem
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_1_mul_mem_wb
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_2_mul_ex_mem
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_2_mul_mem_wb
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_ex_mem
add wave -noupdate -color {Dark Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rd_mem_wb
add wave -noupdate -divider {RS 1}
add wave -noupdate -color {Medium Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rs_1_id
add wave -noupdate -color {Medium Orchid} -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rs_1_id_ex
add wave -noupdate -divider {RS 2}
add wave -noupdate -color Orchid -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rs_2_id
add wave -noupdate -color Orchid -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/fwu_inst/rs_2_id_ex
add wave -noupdate -divider {RD 1}
add wave -noupdate -color Violet -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_1_mul_ex_mem
add wave -noupdate -color Violet -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_1_mul_mem_wb
add wave -noupdate -color Violet -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_1_mul_mux_out
add wave -noupdate -color Violet -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_1_mul_pipe_ex
add wave -noupdate -divider {RD 2}
add wave -noupdate -color Plum -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_2_mul_ex_mem
add wave -noupdate -color Plum -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_2_mul_mem_wb
add wave -noupdate -color Plum -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_2_mul_mux_in
add wave -noupdate -color Plum -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_2_mul_mux_out
add wave -noupdate -color Plum -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_2_mul_pipe_ex
add wave -noupdate -divider RD
add wave -noupdate -color Thistle -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_ex
add wave -noupdate -color Thistle -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_id
add wave -noupdate -color Thistle -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_id_ex
add wave -noupdate -color Thistle -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_ex_mem
add wave -noupdate -color Thistle -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rd_mem_wb
add wave -noupdate -divider STACK
add wave -noupdate -format Literal -radix unsigned -expand /tb/dlx_inst/datapath_inst/stack_inst/stack_mem
add wave -noupdate -format Literal /tb/dlx_inst/datapath_inst/stack_inst/address
add wave -noupdate -format Logic /tb/dlx_inst/datapath_inst/stack_inst/call
add wave -noupdate -format Logic /tb/dlx_inst/datapath_inst/stack_inst/fill
add wave -noupdate -format Logic /tb/dlx_inst/datapath_inst/stack_inst/ret
add wave -noupdate -format Logic /tb/dlx_inst/datapath_inst/stack_inst/spill
add wave -noupdate -format Literal -radix unsigned /tb/dlx_inst/datapath_inst/rf_out_2_id
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2500 ps} 0}
configure wave -namecolwidth 199
configure wave -valuecolwidth 55
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {49040 ps}
