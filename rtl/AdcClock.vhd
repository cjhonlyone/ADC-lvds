-----------------------------------------------------------------------------------------------
-- ï¿? Copyright 2012, Xilinx, Inc. All rights reserved.
-- This file contains confidential and proprietary information of Xilinx, Inc. and is
-- protected under U.S. and international copyright and other intellectual property laws.
-----------------------------------------------------------------------------------------------
--
-- Disclaimer:
--		This disclaimer is not a license and does not grant any rights to the materials
--		distributed herewith. Except as otherwise provided in a valid license issued to you
--		by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE MATERIALS
--		ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL
--		WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED
--		TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR
--		PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort, including
--		negligence, or under any other theory of liability) for any loss or damage of any
--		kind or nature related to, arising under or in connection with these materials,
--		including for any direct, or any indirect, special, incidental, or consequential
--		loss or damage (including loss of data, profits, goodwill, or any type of loss or
--		damage suffered as a result of any action brought by a third party) even if such
--		damage or loss was reasonably foreseeable or Xilinx had been advised of the
--		possibility of the same.
--
-- CRITICAL APPLICATIONS
--		Xilinx products are not designed or intended to be fail-safe, or for use in any
--		application requiring fail-safe performance, such as life-support or safety devices
--		or systems, Class III medical devices, nuclear facilities, applications related to
--		the deployment of airbags, or any other applications that could lead to death,
--		personal injury, or severe property or environmental damage (individually and
--		collectively, "Critical Applications"). Customer assumes the sole risk and
--		liability of any use of Xilinx products in Critical Applications, subject only to
--		applicable laws and regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
--		Contact:    e-mail  hotline@xilinx.com        phone   + 1 800 255 7778
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor:                Xilinx
-- \   \   \/    Version:               V0,03
--  \   \        Filename:              AdcClock.vhd
--  /   /        Date Last Modified:  	12 Feb 2018
-- /___/   /\    Date Created: 			08 Jun 2009
-- \   \  /  \
--  \___\/\___\
--
-- Device: 		Virtex-6, 7-series
-- Author:		Marc Defossez
-- Entity Name:	AdcClock
-- Purpose: 	Clock control for an ADC interface.
-- Tools:		Vivado_2017.3 or later
-- Limitations: none
--
-- Revision History:
--    Rev.
--
-----------------------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
-----------------------------------------------------------------------------------------------
--
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.std_logic_UNSIGNED.all;
	use IEEE.std_logic_arith.all;
library UNISIM;
	use UNISIM.VCOMPONENTS.all;
-----------------------------------------------------------------------------------------------
-- Entity pin description
-----------------------------------------------------------------------------------------------
entity AdcClock is
	generic (
	   C_BufioLoc  : string := "BUFIO_X0Y17"; -- IO-bank 16
	   C_BufrLoc   : string := "BUFR_X0Y17";
	   C_AdcBits   : integer := 16;
	   C_StatTaps  : integer := 16
	);
    port (
        BitClk				: in std_logic;
        BitClkRst			: in std_logic;
        BitClkEna			: in std_logic;
        BitClkReSync		: in std_logic;
        BitClk_MonClkOut	: out std_logic;   -- CLK output
        BitClk_MonClkIn		: in std_logic;    -- ISERDES.CLK input
        BitClk_RefClkOut	: out std_logic;   -- CLKDIV & logic output
        BitClk_RefClkIn		: in std_logic;    -- CLKDIV & logic input
        BitClkAlignWarn 	: out std_logic;
		BitClkInvrtd		: out std_logic;
        BitClkDone 			: out std_logic
    );
end AdcClock;
-----------------------------------------------------------------------------------------------
-- Arcitecture section
-----------------------------------------------------------------------------------------------
architecture AdcClock_struct of AdcClock is
-----------------------------------------------------------------------------------------------
-- Component Instantiation
-----------------------------------------------------------------------------------------------
-- Components are instantiated by means / through the use of library references.
-----------------------------------------------------------------------------------------------
-- Constants, Signals and Attributes Declarations
-----------------------------------------------------------------------------------------------
-- Constants
constant Low	: std_logic := '0';
constant LowNibble : std_logic_vector(4 downto 0) := "00000";
constant High : std_logic := '1';
-- Signals
signal IntBitClkRst				: std_logic;
---------- ISRDS signals ------------------
signal IntClkCtrlDlyCe			: std_logic;
signal IntClkCtrlDlyInc			: std_logic;
signal IntClkCtrlDlyRst			: std_logic;

signal IntBitClk_Ddly			: std_logic;
signal IntBitClk				: std_logic;
signal IntClkCtrlIsrdsMtoS1		: std_logic;
signal IntClkCtrlIsrdsMtoS2		: std_logic;
signal IntClkCtrlOut			: std_logic_vector(7 downto 0);
---------- Controller signals -------------
signal IntCal					: std_logic;
signal IntVal					: std_logic;
signal IntCalVal				: std_logic_vector (1 downto 0);
signal IntProceedCnt			: std_logic_vector (2 downto 0);
signal IntproceedCntTc			: std_logic;
signal IntproceedCntTc_d		: std_logic;
signal IntProceed				: std_logic;
signal IntProceedDone			: std_logic;

type StateType is (Idle, A, B, C, D, E, F, G, G1, H, K, K1, K2, IdlyIncDec, Done);
signal State : StateType;
signal ReturnState : StateType;

signal PassedSubState		: std_logic;
signal IntNumIncDecIdly		: std_logic_vector (3 downto 0);
signal IntAction			: std_logic_vector (1 downto 0);
signal IntClkCtrlDone 		: std_logic;
signal IntClkCtrlAlgnWrn	: std_logic;
signal IntClkCtrlInvrtd		: std_logic;
signal IntTurnAroundBit		: std_logic;
signal IntCalValReg			: std_logic_vector (1 downto 0);
signal IntTimeOutCnt		: std_logic_vector (3 downto 0);
signal IntStepCnt	 		: std_logic_vector (3 downto 0);
-- Attributes
attribute KEEP_HIERARCHY : string;
    attribute KEEP_HIERARCHY of AdcClock_struct : architecture is "YES";
attribute LOC : string;
    attribute LOC of AdcClock_I_Bufio : label is C_BufioLoc;
-- The BUFR is generated through a generate statement and therefore the LOC attribute
-- must be place into the generate statement.
-- See the BUFR generation down in the source code.
-----------------------------------------------------------------------------------------------
begin
-----------------------------------------------------------------------------------------------
-- Bit clock capture ISERDES Master-Slave combination
-----------------------------------------------------------------------------------------------
--
AdcClock_I_Iodly : IDELAYE2 --_FINEDELAY
    generic map (
        SIGNAL_PATTERN          => "CLOCK",
        REFCLK_FREQUENCY        => 200.0,
        HIGH_PERFORMANCE_MODE   => "TRUE",
        --FINEDELAY             => "BYPASS",
        DELAY_SRC               => "IDATAIN",
        CINVCTRL_SEL            => "FALSE",
        IDELAY_TYPE             => "VARIABLE",
        IDELAY_VALUE            => C_StatTaps,
        PIPE_SEL                => "FALSE",
        IS_C_INVERTED           => '0',
        IS_DATAIN_INVERTED      => '0',
        IS_IDATAIN_INVERTED     => '1'
    )
    port map (
        DATAIN          => Low, -- in
        IDATAIN         => BitClk, -- in
        CE              => IntClkCtrlDlyCe, -- in
        INC             => IntClkCtrlDlyInc, -- in
        C               => BitClk_RefClkIn, -- in
        LD              => IntClkCtrlDlyRst, -- in
        LDPIPEEN        => Low, -- in
        REGRST          => IntClkCtrlDlyRst, -- in
        DATAOUT         => IntBitClk_Ddly, -- out
        CINVCTRL        => Low, -- in
        CNTVALUEOUT     => open, -- out [4:0]
        CNTVALUEIN      => LowNibble -- in [4:0]
    );
IntClkCtrlDlyRst <= BitClkRst;
--
AdcClock_I_Isrds_Master : ISERDESE2
    generic map (
        SERDES_MODE         => "MASTER",
        INTERFACE_TYPE      => "NETWORKING",
        IOBDELAY            => "IBUF",
        DATA_RATE           => "SDR",
        DATA_WIDTH          => 8,
        DYN_CLKDIV_INV_EN   => "FALSE",
        DYN_CLK_INV_EN      => "FALSE",
        NUM_CE              => 1,
        OFB_USED            => "FALSE",
        INIT_Q1             => '0',
        INIT_Q2             => '0',
        INIT_Q3             => '0',
        INIT_Q4             => '0',
        SRVAL_Q1            => '0',
        SRVAL_Q2            => '0',
        SRVAL_Q3            => '0',
        SRVAL_Q4            => '0',
        IS_CLKB_INVERTED    => '0', -- CLKB clock input is NOT inverted
        IS_CLKDIVP_INVERTED => '0', -- CLKDIVP input is NOT inverted
        IS_CLKDIV_INVERTED  => '0', -- CLKDIV clock input is NOT inverted
        IS_CLK_INVERTED     => '0', -- CLK clock input is NOT inverted
        IS_D_INVERTED       => '0', -- D (data) input is NOT inverted
        IS_OCLKB_INVERTED   => '0', -- OCLKB clock input is NOT inverted
        IS_OCLK_INVERTED    => '0'  -- OCLK clock input is NOT inverted
    )
    port map (
        D               => BitClk,          -- in	Clock from clock input IBUFDS
        DDLY            => IntBitClk_Ddly,  -- in
        DYNCLKDIVSEL    => Low, -- in
        DYNCLKSEL       => Low, -- in
        OFB             => Low, -- in
        BITSLIP         => Low, -- in
        CE1             => BitClkEna, -- in
        CE2             => Low, -- in
        RST             => IntBitClkRst, -- in
        CLK             => BitClk_MonClkIn, -- in
        CLKB            => Low, -- in
        CLKDIV          => BitClk_RefClkIn, -- in
        CLKDIVP         => Low, -- in
        OCLK            => Low, -- in
        OCLKB           => Low, -- in
        SHIFTIN1        => Low, -- in
        SHIFTIN2        => Low, -- in
        O               => IntBitClk, -- out
        Q1              => IntClkCtrlOut(0), -- out
        Q2              => IntClkCtrlOut(1), -- out
        Q3              => IntClkCtrlOut(2), -- out
        Q4              => IntClkCtrlOut(3), -- out
        Q5              => IntClkCtrlOut(4), -- out
        Q6              => IntClkCtrlOut(5), -- out
        Q7              => IntClkCtrlOut(6), -- out
        Q8              => IntClkCtrlOut(7), -- out
        SHIFTOUT1       => open, -- out
        SHIFTOUT2       => open -- out
    );
-- Input from ISERDES.O	  -- Output and CLK for all ISERDES
AdcClock_I_Bufio : BUFIO
	port map (I => IntBitClk, O => BitClk_MonClkOut);
--
Gen_Bufr_Div_3 : if (C_AdcBits = 12) generate
    attribute LOC of AdcClock_I_Bufr : label is C_BufrLoc;
begin
	AdcClock_I_Bufr : BUFR
		generic map (BUFR_DIVIDE => "3", SIM_DEVICE => "7SERIES") -- 12-bit = DIV by 3
--      ISERDES.CLK, from BUFIO.O -- ISERDES.CLKDIV, word clock for all ISERDES.
		port map  (I => IntBitClk, O => BitClk_RefClkOut, CE => High, CLR => Low);
end generate;
--
Gen_Bufr_Div_5 : if (C_AdcBits = 14) generate
    attribute LOC of AdcClock_I_Bufr : label is C_BufrLoc;
begin
	AdcClock_I_Bufr : BUFR
		generic map (BUFR_DIVIDE => "7", SIM_DEVICE => "7SERIES") -- 12-bit = DIV by 3
--      ISERDES.CLK, from BUFIO.O -- ISERDES.CLKDIV, word clock for all ISERDES.
		port map  (I => IntBitClk, O => BitClk_RefClkOut, CE => High, CLR => Low);
end generate;
--
Gen_Bufr_Div_4 : if (C_AdcBits = 16) generate
    attribute LOC of AdcClock_I_Bufr : label is C_BufrLoc;
begin
	AdcClock_I_Bufr : BUFR
		generic map (BUFR_DIVIDE => "4", SIM_DEVICE => "7SERIES") -- 14- and 16-bit = DIV by 4
--      ISERDES.CLK, from BUFIO.O -- ISERDES.CLKDIV, word clock for all ISERDES.
		port map  (I => IntBitClk, O => BitClk_RefClkOut, CE => High, CLR => Low);
end generate;
-----------------------------------------------------------------------------------------------
-- Bit clock re-synchronizer
-----------------------------------------------------------------------------------------------
IntBitClkRst <= BitClkRst or BitClkReSync;
-----------------------------------------------------------------------------------------------
-- Bit clock controller for clock alignment input.
-----------------------------------------------------------------------------------------------
-- This input section makes sure 64 bits are captured before action is taken to pass to
-- the state machine for evaluation.
-- 8 samples of the Bit Clock are taken by the ISERDES and then transferred to the parallel
-- FPGA world. The Proceed counter needs 8 reference clock rising edges before terminal count.
-- The Proceed counter terminal count then loads the 2 control bits (made from sampled clock)
-- into an intermediate register (IntCalVal).
--
-- IntCal = '1' when all outputs of the ISERDES are '1 else it's '0'.
-- IntVal = '1' when all outputs are '0' or '1'.
--
IntCal <= IntClkCtrlOut(7) and IntClkCtrlOut(6) and IntClkCtrlOut(5) and
			IntClkCtrlOut(4) and IntClkCtrlOut(3) and IntClkCtrlOut(2) and
			IntClkCtrlOut(1) and IntClkCtrlOut(0);
IntVal <= '1' when (IntClkCtrlOut = "11111111" or IntClkCtrlOut = "00000000") else '0';
--
AdcClock_Proceed_PROCESS : process (BitClkEna, IntBitClkRst, BitClk_RefClkIn, IntProceedDone, IntClkCtrlDone)
begin
	if (IntBitClkRst = '1') then
		IntProceedCnt <= (others => '0');
		IntProceedCntTc_d <= '0';
		IntCalVal <= (others => '0');
		IntProceed <= '0';
	elsif (BitClk_RefClkIn'event and BitClk_RefClkIn = '1') then
		if (BitClkEna = '1' and IntClkCtrlDone = '0') then
			IntProceedCnt <= IntProceedCnt + 1;
			IntProceedCntTc_d <= IntProceedCntTc;
			if (IntProceedCntTc_d = '1') then
				IntCalVal <= IntCal & IntVal;
			end if;
			if (IntProceedCntTc_d = '1') then
				IntProceed <= '1';
			elsif (IntProceedDone = '1') then
				IntProceed <= '0';
			end if;
		end if;
	end if;
end process;
IntProceedCntTc <= '1' when (IntProceedCnt = "110") else '0';
-----------------------------------------------------------------------------------------------
-- Bit clock controller for clock alignment state machine.
-----------------------------------------------------------------------------------------------
BitClkAlignWarn <= IntClkCtrlAlgnWrn;
BitClkInvrtd <= IntClkCtrlInvrtd;
BitClkDone <= IntClkCtrlDone;

AdcClock_State_PROCESS : process (BitClk_RefClkIn, IntBitClkRst, BitClkEna, IntProceed, IntCalVal)
subtype ActCalVal is std_logic_vector (4 downto 0);
begin
	if (IntBitClkRst = '1') then
		State				<= Idle;
		ReturnState			<= Idle;
		PassedSubState		<= '0';
		--
		IntNumIncDecIdly	<= "0000";	-- Max. 16
		IntAction			<= "00";
		IntClkCtrlDlyInc	<= '1';
		IntClkCtrlDlyCe		<= '0';
		IntClkCtrlDone 		<= '0';
		IntClkCtrlAlgnWrn	<= '0';
		IntClkCtrlInvrtd	<= '0';
		IntTurnAroundBit	<= '0';
		IntProceedDone		<= '0';
		IntClkCtrlDone		<= '0';
		IntCalValReg		<= (others => '0');		-- 2-bit
		IntTimeOutCnt		<= (others => '0');		-- 4-bit
		IntStepCnt	 		<= (others => '0');		-- 4-bit (16)
	elsif (BitClk_RefClkIn'event and BitClk_RefClkIn = '1') then
		if (BitClkEna = '1' and IntClkCtrlDone = '0') then
		case State is
			when Idle =>
				IntProceedDone <= '0';
				PassedSubState <= '0';
		        IntStepCnt	   <= (others => '0');
				case ActCalVal'(IntAction(1 downto 0) & IntCalVal (1 downto 0) & IntProceed) is
					when "00001" => State <= A;
					when "01001" => State <= B;
					when "10001" => State <= B;
					when "11001" => State <= B;
					when "01111" => State <= C;
					when "01101" => State <= D;
					when "01011" => State <= D;
					when "00011" => State <= E;
					when "00101" => State <= E;
					when "00111" => State <= E;
					when "10011" => State <= F;
					when "11011" => State <= F;
					when "10101" => State <= F;
					when "11101" => State <= F;
					when "10111" => State <= F;
					when "11111" => State <= F;
					when others => State <= Idle;
				end case;
			when A => 						-- First time and sampling in jitter or cross area.
				IntAction <= "01";					-- Set the action bits and go to next step.
				State <= B;
			when B =>						-- Input is sampled in jitter or clock cross area.
				if (PassedSubState = '1') then
					PassedSubState <= '0';			-- Clear the pass through the substate bit.
					IntProceedDone <= '1';			-- Reset the proceed bit.
					State <= Idle;					-- Return for a new sample of the input.
				elsif (IntTimeOutCnt = "1111") then	-- When arriving here something is wrong.
					IntTimeOutCnt <= "0000";		-- Reset the counter.
					IntAction <= "00";				-- reset the action bits.
					IntClkCtrlAlgnWrn <= '1';		-- Raise a FLAG.
					IntProceedDone <= '1';			-- Reset the proceed bit.
					State <= Idle;					-- Retry, return for new sample of input.
				else
					IntTimeOutCnt <= IntTimeOutCnt + 1;
					IntNumIncDecIdly <= "0010";		-- Number increments or decrements to do.
					ReturnState <= State;			-- This state is the state to return too.
					IntProceedDone <= '1';			-- Reset the proceed bit.
					IntClkCtrlDlyInc <= '1';		-- Set for increment.
					State <= IdlyIncDec;			-- Jump to Increment/decrement sub-state.
				end if;
			when C =>						-- After first sample, jitter or cross, is now high.
				IntNumIncDecIdly <= "0010";			-- Number increments or decrements to do.
				ReturnState <= Done;				-- This state is the state to return too.
				IntClkCtrlDlyInc	<= '0';			-- Set for decrement.
				State <= IdlyIncDec;
			when D =>						-- Same as C but with indication of 180-deg shift.
				IntClkCtrlInvrtd <= '1';
				State <= C;
			when E =>						-- First saple with valid data.
				IntCalValReg <= IntCalVal;			-- Register the sampled value
				IntAction <= "10";
				IntProceedDone <= '1';				-- Reset the proceed bit.
				IntNumIncDecIdly <= "0001";			-- Number increments or decrements to do.
				ReturnState <= Idle;				-- When increment is done return sampling.
				IntClkCtrlDlyInc <= '1';			-- Set for increment
				State <= IdlyIncDec;				-- Jump to Increment/decrement sub-state.
			when F =>						-- Next samples with valid data.
				if (IntCalVal /= IntCalValReg) then
					State <= G;				-- The new CalVal value is different from the first.
				else
					if (IntStepCnt = "1111") then 	-- Step counter at the end, 15
						if (IntTurnAroundBit = '0') then
							State <= H;				-- No edge found and first time here.
						elsif (IntCalValReg = "11") then
							State <= K;			-- A turnaround already happend.
						else					-- No edge is found (large 1/2 period).
							State <= K1;		-- Move the clock edge to near the correct
						end if;					-- edge.
					else
						IntStepCnt <= IntStepCnt + 1;
						IntNumIncDecIdly <= "0001";	-- Number increments or decrements to do.
						IntProceedDone <= '1';		-- Reset the proceed bit.
						ReturnState <= Idle;		-- When increment is done return sampling.
						IntClkCtrlDlyInc <= '1';	-- Set for increment
						State <= IdlyIncDec;		-- Jump to Increment/decrement sub-state.
					end if;
				end if;
			when G =>
				if (IntCalValReg /= "01") then
					IntClkCtrlInvrtd <= '1';
					State <= G1;
				else
					State <= G1;
				end if;
			when G1 =>
				if (IntTimeOutCnt = "00") then
					State <= Done;
				else
					IntNumIncDecIdly <= "0010";	-- Number increments or decrements to do.
					ReturnState <= Done;		-- After decrement it's finished.
					IntClkCtrlDlyInc <= '0';	-- Set for decrement
					State <= IdlyIncDec;		-- Jump to the Increment/decrement sub-state.
				end if;
			when H =>
				IntTurnAroundBit <= '1';		-- Indicate that the Idelay jumps to 0.
				IntStepCnt <= IntStepCnt + 1;	-- Set all registers to zero.
				IntAction <= "00";				-- Take one step, let the counter flow over
				IntCalValReg <= "00";			-- The idelay turn over to 0.
				IntTimeOutCnt <= "0000";		-- Start sampling from scratch.
				IntNumIncDecIdly <= "0001";		-- Number increments or decrements to do.
				IntProceedDone <= '1';			-- Reset the proceed bit.
				ReturnState <= Idle;			-- After increment go sampling for new.
				IntClkCtrlDlyInc <= '1';		-- Set for increment.
				State <= IdlyIncDec;			-- Jump to the Increment/decrement sub-state.
			when K =>
				IntNumIncDecIdly <= "1111";		-- Number increments or decrements to do.
				ReturnState <= K2;				-- After increment it is done.
				IntClkCtrlDlyInc <= '1';		-- Set for increment.
				State <= IdlyIncDec;			-- Jump to the Increment/decrement sub-state.
			when K1 =>
				IntNumIncDecIdly <= "1110";		-- Number increments or decrements to do.
				ReturnState <= K2;				-- After increment it is done.
				IntClkCtrlDlyInc <= '1';		-- Set for increment.
				State <= IdlyIncDec;			-- Jump to the Increment/decrement sub-state.
			when K2 =>
				IntNumIncDecIdly <= "0001";		-- Number increments or decrements to do.
				ReturnState <= Done;			-- After increment it is done.
				IntClkCtrlDlyInc <= '1';		-- Set for increment.
				State <= IdlyIncDec;			-- Jump to the Increment/decrement sub-state.
			--
			when IdlyIncDec =>				-- Increment or decrement by enable.
				if (IntNumIncDecIdly /= "0000") then			-- Check number of tap jumps
					IntNumIncDecIdly <= IntNumIncDecIdly - 1;	-- If not 0 jump and decrement.
					IntClkCtrlDlyCe <= '1';						-- Do the jump. enable it.
				else
					IntClkCtrlDlyCe <= '0';		-- when it is enabled, disbale it
					PassedSubState <= '1';		-- Set a check bit "I've been here and passed".
					State <= ReturnState;		-- Return to origin.
				end if;
			when Done =>					-- Alignment done.
				IntClkCtrlDone <= '1';				-- Alignment is done.
		end case;
		end if;
	end if;
end process;
--
------------------------------------------------------------------------------------------------
end  AdcClock_struct;
