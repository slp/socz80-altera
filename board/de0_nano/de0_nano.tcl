# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

# Quartus II: Generate Tcl File for Project
# File: de0_nano.tcl
# Generated on: Sat Sep  6 02:27:17 2014

# Load Quartus II Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "de0_nano"]} {
		puts "Project de0_nano is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists de0_nano]} {
		project_open -revision de0_nano de0_nano
	} else {
		project_new -revision de0_nano de0_nano
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone IV E"
	set_global_assignment -name DEVICE EP4CE22F17C6
	set_global_assignment -name TOP_LEVEL_ENTITY top_level
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 13.1
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "19:30:55  AUGUST 28, 2014"
	set_global_assignment -name LAST_QUARTUS_VERSION 13.1
	set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (VHDL)"
	set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "2.5 V"
	set_global_assignment -name VHDL_FILE ../../vhdl/board/de0_nano/SDRAM_Controller.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/DRAM.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/gpio.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/board/de0_nano/top_level_de0_nano.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/Z80cpu.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80_Pack.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80_ALU.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80_MCode.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80_Reg.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/T80se.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/MMU.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/MonZ80.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/SSRAM.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/uart_interface.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/fifo.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/uart.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/timer.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/board/de0_nano/pll_de0_nano.vhd
	set_global_assignment -name VHDL_FILE ../../vhdl/clkscale.vhd
        set_global_assignment -name VHDL_FILE ../../vhdl/RAM4K36.vhd
        set_global_assignment -name VHDL_FILE ../../vhdl/RAM4K9.vhd
	set_location_assignment PIN_J15 -to rst_n_pad_i
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n_pad_i
	set_location_assignment PIN_R8 -to sys_clk_pad_i
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sys_clk_pad_i
	set_location_assignment PIN_F13 -to serial_rx
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to serial_rx
	set_location_assignment PIN_T15 -to serial_tx
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to serial_tx
	set_location_assignment PIN_A15 -to leds[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[0]
	set_location_assignment PIN_A13 -to leds[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[1]
	set_location_assignment PIN_B13 -to leds[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[2]
	set_location_assignment PIN_A11 -to leds[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[3]
	set_location_assignment PIN_D1 -to leds[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to leds[4]
	set_location_assignment PIN_P2 -to SDRAM_ADDR[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[0]
	set_location_assignment PIN_N5 -to SDRAM_ADDR[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[1]
	set_location_assignment PIN_N6 -to SDRAM_ADDR[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[2]
	set_location_assignment PIN_M8 -to SDRAM_ADDR[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[3]
	set_location_assignment PIN_P8 -to SDRAM_ADDR[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[4]
	set_location_assignment PIN_T7 -to SDRAM_ADDR[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[5]
	set_location_assignment PIN_N8 -to SDRAM_ADDR[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[6]
	set_location_assignment PIN_T6 -to SDRAM_ADDR[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[7]
	set_location_assignment PIN_R1 -to SDRAM_ADDR[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[8]
	set_location_assignment PIN_P1 -to SDRAM_ADDR[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[9]
	set_location_assignment PIN_N2 -to SDRAM_ADDR[10]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[10]
	set_location_assignment PIN_N1 -to SDRAM_ADDR[11]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[11]
	set_location_assignment PIN_L4 -to SDRAM_ADDR[12]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_ADDR[12]
	set_location_assignment PIN_G2 -to SDRAM_DQ[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[0]
	set_location_assignment PIN_G1 -to SDRAM_DQ[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[1]
	set_location_assignment PIN_L8 -to SDRAM_DQ[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[2]
	set_location_assignment PIN_K5 -to SDRAM_DQ[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[3]
	set_location_assignment PIN_K2 -to SDRAM_DQ[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[4]
	set_location_assignment PIN_J2 -to SDRAM_DQ[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[5]
	set_location_assignment PIN_J1 -to SDRAM_DQ[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[6]
	set_location_assignment PIN_R7 -to SDRAM_DQ[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[7]
	set_location_assignment PIN_T4 -to SDRAM_DQ[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[8]
	set_location_assignment PIN_T2 -to SDRAM_DQ[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[9]
	set_location_assignment PIN_T3 -to SDRAM_DQ[10]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[10]
	set_location_assignment PIN_R3 -to SDRAM_DQ[11]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[11]
	set_location_assignment PIN_R5 -to SDRAM_DQ[12]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[12]
	set_location_assignment PIN_P3 -to SDRAM_DQ[13]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[13]
	set_location_assignment PIN_N3 -to SDRAM_DQ[14]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[14]
	set_location_assignment PIN_K1 -to SDRAM_DQ[15]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQ[15]
	set_location_assignment PIN_R6 -to SDRAM_DQM[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQM[0]
	set_location_assignment PIN_T5 -to SDRAM_DQM[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_DQM[1]
	set_location_assignment PIN_M7 -to SDRAM_BA[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_BA[0]
	set_location_assignment PIN_M6 -to SDRAM_BA[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_BA[1]
	set_location_assignment PIN_L1 -to SDRAM_nCAS
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nCAS
	set_location_assignment PIN_L7 -to SDRAM_CKE
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_CKE
	set_location_assignment PIN_P6 -to SDRAM_CS
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_CS
	set_location_assignment PIN_L2 -to SDRAM_nRAS
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nRAS
	set_location_assignment PIN_C2 -to SDRAM_nWE
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_nWE
	set_location_assignment PIN_R4 -to SDRAM_CLK
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_CLK
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_command"
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_address"
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_dqm"
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_cke"
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_bank"
	set_instance_assignment -name FAST_INPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|iob_data"
	set_instance_assignment -name FAST_INPUT_REGISTER ON -to "DRAM:dram|SDRAM_Controller:sdram_ctrl|captured_data"
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_ADDR
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_BA
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_CKE
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_CLK
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_CS
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_DQM
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_nCAS
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_nRAS
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_nWE
	set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_DQ
	set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM_DQ
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}
