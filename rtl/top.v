`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/26 16:26:49
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module top # (
    parameter C_AdcChnls = 2,     // Number of ADC in a package
    parameter C_AdcWireInt = 2,  // 2 = 2-wire, 1 = 1-wire interface
    parameter C_AdcBits = 14,
    parameter C_AdcBytOrBitMode = 0, // 1 = BIT mode, 0 = BYTE mode,
    parameter C_AdcMsbOrLsbFst = 1 // 0 = MSB first, 1 = LSB first
)
(
    input DCLK_p_pin,
    input DCLK_n_pin,
    input FCLK_p_pin,
    input FCLK_n_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_p_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_n_pin,

    input SysClk_p_pin,
    input SysClk_n_pin,
    input SysRst,
    
    
    
    inout [14:0]DDR_0_addr,
    inout [2:0]DDR_0_ba,
    inout DDR_0_cas_n,
    inout DDR_0_ck_n,
    inout DDR_0_ck_p,
    inout DDR_0_cke,
    inout DDR_0_cs_n,
    inout [3:0]DDR_0_dm,
    inout [31:0]DDR_0_dq,
    inout [3:0]DDR_0_dqs_n,
    inout [3:0]DDR_0_dqs_p,
    inout DDR_0_odt,
    inout DDR_0_ras_n,
    inout DDR_0_reset_n,
    inout DDR_0_we_n,
    inout FIXED_IO_0_ddr_vrn,
    inout FIXED_IO_0_ddr_vrp,
    inout [53:0]FIXED_IO_0_mio,
    inout FIXED_IO_0_ps_clk,
    inout FIXED_IO_0_ps_porb,
    inout FIXED_IO_0_ps_srstb,
    
    // ADC is Slave
    output ADC_SCLK,
    input  ADC_MISO,
    output ADC_CS,
    output ADC_MOSI,
    output ADC_PDN,
    output ADC_RESET
);

    
    wire SysClk100M;
    
    wire SysRefClk        ;
    wire AdcIntrfcRst     ;
    wire AdcIntrfcEna     ;
    wire AdcReSync        ;
//    wire AdcFrmSyncWrn    ;
    wire AdcBitClkAlgnWrn ;
    wire AdcBitClkInvrtd  ;
//    wire AdcBitClkDone    ;
    wire AdcIdlyCtrlRdy   ;
    
    wire MMCM_Rst;
    MMCM Inst_MMCM
     (
         // Clock in ports
        .CLK_IN1_p(SysClk_p_pin),
        .CLK_IN1_n(SysClk_n_pin),
          // Clock out ports
        .CLK_OUT1(SysClk100M),
        .CLK_OUT2(SysRefClk),
        .CLK_OUT3(),
          // Status and control signals
        .RESET(0),
        .LOCKED(MMCM_Rst)
     );
     assign ADC_PDN = 0;
     assign ADC_RESET = ~MMCM_Rst;
     
    wire AdcDataValid;
    wire [13:0] AdcDataCh0;
    wire [13:0] AdcDataCh1;
    wire [13:0] AdcDataCh2;
    wire [13:0] AdcDataCh3;
    
	ADC344x_Top #(
             .C_AdcChnls(C_AdcChnls),
             .C_AdcWireInt(C_AdcWireInt)
         ) inst_ADC3444_Top (
             .DCLK_p_pin   (DCLK_p_pin),
             .DCLK_n_pin   (DCLK_n_pin),
             .FCLK_p_pin   (FCLK_p_pin),
             .FCLK_n_pin   (FCLK_n_pin),
             .DATA_p_pin   (DATA_p_pin),
             .DATA_n_pin   (DATA_n_pin),
             .SysDlyClk    (SysRefClk),
             .SysRst       (~MMCM_Rst),
             .SysSampleClk (SysClk100M),
             .SysSampleRst (1'b0),
             .AdcDataValid (AdcDataValid),
             .AdcDataCh0   (AdcDataCh0),
             .AdcDataCh1   (AdcDataCh1),
             .AdcDataCh2   (AdcDataCh2),
             .AdcDataCh3   (AdcDataCh3)
         );
         
    ila_0 Inst_ila
    (
        .clk(SysClk100M),
        .probe0(AdcDataCh0[13:0]),
        .probe1(AdcDataCh1[13:0]),
        .probe2(AdcDataCh2[13:0]),
        .probe3(AdcDataCh3[13:0]),
        .probe4(AdcDataValid)
    );
  design_1_wrapper design_1_i
         (.DDR_0_addr(DDR_0_addr),
          .DDR_0_ba(DDR_0_ba),
          .DDR_0_cas_n(DDR_0_cas_n),
          .DDR_0_ck_n(DDR_0_ck_n),
          .DDR_0_ck_p(DDR_0_ck_p),
          .DDR_0_cke(DDR_0_cke),
          .DDR_0_cs_n(DDR_0_cs_n),
          .DDR_0_dm(DDR_0_dm),
          .DDR_0_dq(DDR_0_dq),
          .DDR_0_dqs_n(DDR_0_dqs_n),
          .DDR_0_dqs_p(DDR_0_dqs_p),
          .DDR_0_odt(DDR_0_odt),
          .DDR_0_ras_n(DDR_0_ras_n),
          .DDR_0_reset_n(DDR_0_reset_n),
          .DDR_0_we_n(DDR_0_we_n),
          .FIXED_IO_0_ddr_vrn(FIXED_IO_0_ddr_vrn),
          .FIXED_IO_0_ddr_vrp(FIXED_IO_0_ddr_vrp),
          .FIXED_IO_0_mio(FIXED_IO_0_mio),
          .FIXED_IO_0_ps_clk(FIXED_IO_0_ps_clk),
          .FIXED_IO_0_ps_porb(FIXED_IO_0_ps_porb),
          .FIXED_IO_0_ps_srstb(FIXED_IO_0_ps_srstb),
         
          .SPI0_MISO_I_0(ADC_MISO),
          .SPI0_MOSI_O_0(ADC_MOSI),
          .SPI0_SCLK_O_0(ADC_SCLK),
          .SPI0_SS_O_0(ADC_CS)
          );
endmodule

//(* CORE_GENERATION_INFO = "dcm,clk_wiz_v3_6,{component_name=dcm,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=MMCM_ADV,num_out_clk=1,clkin1_period=8.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=MANUAL,manual_override=false}" *)
module MMCM
 (// Clock in ports
  input         CLK_IN1_p,
  input         CLK_IN1_n,
  // Clock out ports
  output        CLK_OUT1,
  output        CLK_OUT2,
  output        CLK_OUT3,
  // Status and control signals
  input         RESET,
  output        LOCKED
 );
 
 wire clkin1;
 wire clkout0;
 wire clkout1;
 wire clkout2;
 // Input buffering
  //------------------------------------
  IBUFDS clkin1_buf
   (.O (clkin1),
    .I (CLK_IN1_p),
    .IB (CLK_IN1_n));


  // Clocking primitive
  //------------------------------------
  // Instantiation of the MMCM primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        clkfbout;
  wire        clkfbout_buf;
  wire        clkfboutb_unused;
  wire        clkout0b_unused;
  wire        clkout1b_unused;
  wire        clkout2b_unused;
  wire        clkout3_unused;
  wire        clkout3b_unused;
  wire        clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (10.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),

    .CLKOUT0_DIVIDE_F     (10.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),

    .CLKOUT1_DIVIDE       (5),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),

    .CLKOUT2_DIVIDE       (4),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  ("FALSE"),

    .CLKIN1_PERIOD        (10.000),
    .REF_JITTER1          (0.010))
  mmcm_adv_inst
    // Output clocks
   (.CLKFBOUT            (clkfbout),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clkout0),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clkout1),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf),
    .CLKIN1              (clkin1),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (LOCKED),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (RESET));

  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clkfbout_buf),
    .I (clkfbout));

  BUFG clkout1_buf
   (.O   (CLK_OUT1),
    .I   (clkout0));

  BUFG clkout2_buf
   (.O   (CLK_OUT2),
    .I   (clkout1));

  BUFG clkout3_buf
   (.O   (CLK_OUT3),
    .I   (clkout2));

endmodule