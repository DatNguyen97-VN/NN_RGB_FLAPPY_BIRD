# Copyright (C) 2020  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions
# and other software and tools, and any partner logic
# functions, and any output files from any of the foregoing
# (including device programming or simulation files), and any
# associated documentation or information are expressly subject
# to the terms and conditions of the Intel Program License
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details, at
# https://fpgasoftware.intel.com/eula.

# Quartus Prime: Generate Tcl File for Project
# File: de0_nano_test.tcl
# Generated on: Sat Apr 10 16:57:48 2021

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
  if {[string compare $quartus(project) "flappy_bird_logic"]} {
    puts "Project flappy_bird_logic is not open"
    set make_assignments 0
  }
} else {
  # Only open if not already open
  if {[project_exists flappy_bird_logic]} {
    project_open -revision flappy_bird_logic flappy_bird_logic
  } else {
    project_new -revision flappy_bird_logic flappy_bird_logic
  }
  set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
  set_global_assignment -name FAMILY "Cyclone IV E"
  set_global_assignment -name DEVICE EP4CE115F29C7
  set_global_assignment -name ORIGINAL_QUARTUS_VERSION 15.1.0
  set_global_assignment -name PROJECT_CREATION_TIME_DATE "08:39:13  OCTOBER 27, 2024"
  set_global_assignment -name LAST_QUARTUS_VERSION "21.1.1 Lite Edition"
  set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
  set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
  set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
  set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
  set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (SYSTEMVERILOG)"
  set_global_assignment -name EDA_OUTPUT_DATA_FORMAT SYSTEMVERILOG -section_id eda_simulation
  set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
  set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
  set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
  set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
  set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
  set_global_assignment -name ENABLE_OCT_DONE OFF
  set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
  set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF
  set_global_assignment -name USE_CONFIGURATION_DEVICE ON
  set_global_assignment -name CYCLONEIII_CONFIGURATION_DEVICE EPCS64
  set_global_assignment -name CRC_ERROR_OPEN_DRAIN OFF
  set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -rise
  set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -fall
  set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -rise
  set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -fall
  # Source File
  set core_src_game_rtl_dir [glob ./../../rtl/flappy_bird/*.sv]
  foreach core_src_game_file $core_src_game_rtl_dir {
    set_global_assignment -name SYSTEMVERILOG_FILE $core_src_game_file
  }

  set core_src_cam_rtl_dir [glob ./../../rtl/ov7670/*.sv]
  foreach core_src_cam_file $core_src_cam_rtl_dir {
    set_global_assignment -name SYSTEMVERILOG_FILE $core_src_cam_file
  }

  set core_src_nn_rtl_dir [glob ./../../rtl/nn_rgb/*.sv]
  foreach core_src_nn_file $core_src_nn_rtl_dir {
    set_global_assignment -name SYSTEMVERILOG_FILE $core_src_nn_file
  }

  set_global_assignment -name SYSTEMVERILOG_FILE ./../../rtl/nn_rgb/sigmoid.v
  # Mem File
  set core_src_mem_dir [glob ./*.v]
  foreach core_src_mem_file $core_src_mem_dir {
    set_global_assignment -name VERILOG_FILE $core_src_mem_file
  }
  # In/Out pins
  set_location_assignment PIN_Y2 -to sys_clk
  set_location_assignment PIN_M23 -to sys_rst_n
  set_location_assignment PIN_AB27 -to slide_sw_resend_reg_values
  set_location_assignment PIN_AD27 -to sel_in[1]
  set_location_assignment PIN_AC27 -to sel_in[0]
  # jumping and backup GreenLed
  set_location_assignment PIN_G21 -to gled[1]
  set_location_assignment PIN_G22 -to gled[0]
  # move
  set_location_assignment PIN_AB28 -to data_in[3]
  # start
  set_location_assignment PIN_AC28 -to data_in[2]
  # jump
  set_location_assignment PIN_M21  -to re_start
  #
  set_location_assignment PIN_F21 -to led_out[3]
  set_location_assignment PIN_E19 -to led_out[2]
  set_location_assignment PIN_F19 -to led_out[1]
  set_location_assignment PIN_G19 -to led_out[0]
  # Camera pins
  set_location_assignment PIN_AE16 -to ov7670_data[7]
  set_location_assignment PIN_AD21 -to ov7670_data[6]
  set_location_assignment PIN_Y16 -to ov7670_data[5]
  set_location_assignment PIN_AC21 -to ov7670_data[4]
  set_location_assignment PIN_Y17 -to ov7670_data[3]
  set_location_assignment PIN_AB21 -to ov7670_data[2]
  set_location_assignment PIN_AC15 -to ov7670_data[1]
  set_location_assignment PIN_AB22 -to ov7670_data[0]
  set_location_assignment PIN_AC22 -to ov7670_href
  set_location_assignment PIN_AC19 -to ov7670_pclk
  set_location_assignment PIN_AD19 -to ov7670_pwdn
  set_location_assignment PIN_AF15 -to ov7670_reset
  set_location_assignment PIN_AF24 -to ov7670_sioc
  set_location_assignment PIN_AE21 -to ov7670_siod
  set_location_assignment PIN_AF25 -to ov7670_vsync
  set_location_assignment PIN_AF16 -to ov7670_xclk
  # VGA pins
  set_location_assignment PIN_D12 -to vga_blue[7]
  set_location_assignment PIN_D11 -to vga_blue[6]
  set_location_assignment PIN_C12 -to vga_blue[5]
  set_location_assignment PIN_A11 -to vga_blue[4]
  set_location_assignment PIN_B11 -to vga_blue[3]
  set_location_assignment PIN_C11 -to vga_blue[2]
  set_location_assignment PIN_A10 -to vga_blue[1]
  set_location_assignment PIN_B10 -to vga_blue[0]
  set_location_assignment PIN_A12 -to vga_clk
  set_location_assignment PIN_C10 -to Nsync
  set_location_assignment PIN_F11 -to Nblank
  set_location_assignment PIN_G13 -to vga_hsync
  set_location_assignment PIN_C13 -to vga_vsync
  set_location_assignment PIN_C9 -to vga_green[7]
  set_location_assignment PIN_F10 -to vga_green[6]
  set_location_assignment PIN_B8 -to vga_green[5]
  set_location_assignment PIN_C8 -to vga_green[4]
  set_location_assignment PIN_H12 -to vga_green[3]
  set_location_assignment PIN_F8 -to vga_green[2]
  set_location_assignment PIN_G11 -to vga_green[1]
  set_location_assignment PIN_G8 -to vga_green[0]
  set_location_assignment PIN_H10 -to vga_red[7]
  set_location_assignment PIN_H8 -to vga_red[6]
  set_location_assignment PIN_J12 -to vga_red[5]
  set_location_assignment PIN_G10 -to vga_red[4]
  set_location_assignment PIN_F12 -to vga_red[3]
  set_location_assignment PIN_D10 -to vga_red[2]
  set_location_assignment PIN_E11 -to vga_red[1]
  set_location_assignment PIN_E12 -to vga_red[0]

  set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

  # Commit assignments
  export_assignments
}