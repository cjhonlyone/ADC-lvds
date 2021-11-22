#--------------------------------------------------------------------------------------------
#-   ____  ____
#-  /   /\/   /
#- /___/  \  /
#- \   \   \/    漏 Copyright 2016 - 2018 Xilinx, Inc. All rights reserved.
#-  \   \        This file contains confidential and proprietary information of Xilinx, Inc.
#-  /   /        and is protected under U.S. and international copyright and other
#- /___/   /\    intellectual property laws.
#- \   \  /
#-  \___\/\___
#-
#--------------------------------------------------------------------------------------------
#- Device:              Ultrascale
#- Author:              Defossez
#- Entity Name:         KC705_AdcToplevel_Toplevel
#- Purpose:             Constraint file for for testing of the Apps hierarchical level
#-                      of design.
#- Tools:               Vivado_2017.3
#- Limitations:         none
#-
#- Vendor:              Xilinx Inc.
#- Version:
#- Filename:            KC705_AdcToplevel_Toplevel.xdc
#- Date Created:        Jan 2016
#- Date Last Modified:  Jan 2016
#--------------------------------------------------------------------------------------------
#- Disclaimer:
#-		This disclaimer is not a license and does not grant any rights to the materials
#-		distributed herewith. Except as otherwise provided in a valid license issued to you
#-		by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE MATERIALS
#-		ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL
#-		WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED
#-		TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR
#-		PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort, including
#-		negligence, or under any other theory of liability) for any loss or damage of any
#-		kind or nature related to, arising under or in connection with these materials,
#-		including for any direct, or any indirect, special, incidental, or consequential
#-		loss or damage (including loss of data, profits, goodwill, or any type of loss or
#-		damage suffered as a result of any action brought by a third party) even if such
#-		damage or loss was reasonably foreseeable or Xilinx had been advised of the
#-		possibility of the same.
#-
#- CRITICAL APPLICATIONS
#-		Xilinx products are not designed or intended to be fail-safe, or for use in any
#-		application requiring fail-safe performance, such as life-support or safety devices
#-		or systems, Class III medical devices, nuclear facilities, applications related to
#-		the deployment of airbags, or any other applications that could lead to death,
#-		personal injury, or severe property or environmental damage (individually and
#-		collectively, "Critical Applications"). Customer assumes the sole risk and
#-		liability of any use of Xilinx products in Critical Applications, subject only to
#-		applicable laws and regulations governing limitations on product liability.
#-
#- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
#-
#- Contact:    e-mail  hotline@xilinx.com        phone   + 1 800 255 7778
#--------------------------------------------------------------------------------------------
#- Revision History:
#-  Rev. 10 Jan 2016
#-      Changed the original UCF file into an XDC file for use with Vivado.
#--------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
# Timing constraints
#-------------------------------------------------------------------------------------------
# ADC Bit clock input is as sample taken at the FPGA pin as 750MHz.
# 700MHz = 1.333ns = ISERDES.CLK and ISERDES.CLKDIV = 5.333ns = 4xCLK
# For the test application only 2-channels are implemented -- > Reason = Loopback hardware 
# testing on Xilinx development board .
# Bit clock input passed though a BUFIO ==> direct/dedicated routing to ISERDES.CLK inputs.
# This path from the package pin to the ISERDES.CLK inputs is routed through an IDELAY,
# BUFIO on dedicated clock nets. Timing cannot improve this and thus this path chould be
# excluded from timing checks.
# Bit clock input passed though BUFR(divide) ==> normal clock routing to ISERDES.CLKDIV.
# This path must be under timing control because the clock is not only used for ISERDES.CLKDIV
# but also for normal clocked logic.
#
create_clock -period 5.494 -name AdcBitClk -waveform {0.000 2.747} [get_ports DCLK_p_pin]
#
# Create a clock path for all that has to do with timing of IDELAY updating.
#create_clock -period 10.000 -name SysRefClk -waveform {0.000 5.000} [get_ports SysClk_p_pin]
#create_clock -period 5.000 -name SysRefClk -waveform {0.000 2.500} [get_ports SysRefClk]
#
# Remove the path from the ADC forwarded clock package pin to all ISERDES.CLK pins from the timing
# engine and timing checking for place&route.
#set_false_path  -from [get_ports DCLK_p_pin] \
#                -through [get_cells Inst_AdcClock/AdcClock_I_Isrds_Master] \
#                -through [get_cells Inst_AdcClock/AdcClock_I_Bufio] \
#                -to [get_cells -hierarchical "*Isrds*"]
#
# Create a clock path for the timing engine from the BUFR output to all elements using this clock.
#create_generated_clock -name AdcBitClkDiv \
#                        -source [get_pins Inst_AdcClock/AdcClock_I_Isrds_Master/DDLY] \
#                        -divide_by 4 [get_nets -hierarchical "*IntClkDiv*"]
#
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks clk_out2_clk_wiz_0]
#set_false_path -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks clk_out2_clk_wiz_0_1]
#
#-------------------------------------------------------------------------------------------
# Create and area for the out_of_context design block.
#-------------------------------------------------------------------------------------------
# Command for logic placed with IO_Bank
#
#create_pblock Apps_AdcToplevel
#resize_pblock [get_pblocks Apps_AdcToplevel] -add {SLICE_X0Y60:SLICE_X7Y89}
#    add_cells_to_pblock [get_pblocks Apps_AdcToplevel] [get_cells -quiet [list \
#        AdcToplevel_Toplevel_I_AdcToplevel
#        ]]
#
#-------------------------------------------------------------------------------------------
# Pin LOC constraints
#-------------------------------------------------------------------------------------------
# BANK13 real VCCO13 = 1.8V but we need LVDS_25 to adopt LVDS standard
# only LVDS_25 can be apply in HR BANK
# LVDS can be apply in HP BANK
set_property -dict {LOC T12  IOSTANDARD LVDS_25} [get_ports DATA_p_pin[0]]; # OU1 A 
set_property -dict {LOC U12  IOSTANDARD LVDS_25} [get_ports DATA_n_pin[0]]; #
#set_property -dict {LOC T14  IOSTANDARD LVDS_25} [get_ports DATA_p_pin[1]]; # OU1 B
#set_property -dict {LOC T15  IOSTANDARD LVDS_25} [get_ports DATA_n_pin[1]]; #

set_property -dict {LOC N17  IOSTANDARD LVDS_25} [get_ports DATA_p_pin[1]]; # invert OU2 A
set_property -dict {LOC P18  IOSTANDARD LVDS_25} [get_ports DATA_n_pin[1]]; # invert
#set_property -dict {LOC V16  IOSTANDARD LVDS_25} [get_ports DATA_p_pin[3]]; # invert OU2 B
#set_property -dict {LOC W16  IOSTANDARD LVDS_25} [get_ports DATA_n_pin[3]]; # invert

set_property -dict {LOC N18  IOSTANDARD LVDS_25} [get_ports FCLK_p_pin];
set_property -dict {LOC P19  IOSTANDARD LVDS_25} [get_ports FCLK_n_pin];
set_property -dict {LOC U14  IOSTANDARD LVDS_25} [get_ports DCLK_p_pin];
set_property -dict {LOC U15  IOSTANDARD LVDS_25} [get_ports DCLK_n_pin];

set_property -dict {LOC W14   IOSTANDARD LVCMOS25} [get_ports spi_clk]; # PLClk
#set_property -dict {LOC W19   IOSTANDARD LVCMOS25} [get_ports spi_miso_i]; # PLClk
set_property -dict {LOC Y19   IOSTANDARD LVCMOS25} [get_ports spi_cs]; # PLClk
set_property -dict {LOC Y14   IOSTANDARD LVCMOS25} [get_ports spi_mosi_o]; # PLClk

#set_property -dict {LOC V19   IOSTANDARD LVCMOS25} [get_ports adc_reset]; # PLClk


# BANK35 1.8V
#set_property -dict {LOC D15   IOSTANDARD LVDS} [get_ports SysClk_p_pin]; # PLClk
#set_property -dict {LOC D14   IOSTANDARD LVDS} [get_ports SysClk_n_pin]; # PLClk
#set_property -dict {LOC H14   IOSTANDARD LVCMOS18} [get_ports adc_pdn]; # PLClk
#
#


#
#-------------------------------------------------------------------------------------------
# The end