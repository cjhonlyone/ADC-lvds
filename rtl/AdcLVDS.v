`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/23 22:26:34
// Design Name: 
// Module Name: AdcLVDS
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


module AdcLVDS #(
    parameter C_AdcChnls = 8,     // Number of ADC in a package
    parameter C_AdcWireInt = 1    // 2 = 2-wire, 1 = 1-wire interface
)
(
    input DCLK_p_pin,
    input DCLK_n_pin,
    input FCLK_p_pin,
    input FCLK_n_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_p_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_n_pin,
    
    input SysRst,
    
    output AdcFrmClk, 
    output [7:0] AdcDataValid,
    output [15:0] AdcDataCh0,
    output [15:0] AdcDataCh1,
    output [15:0] AdcDataCh2,
    output [15:0] AdcDataCh3,
    output [15:0] AdcDataCh4,
    output [15:0] AdcDataCh5,
    output [15:0] AdcDataCh6,
    output [15:0] AdcDataCh7
    );

    // Pin to IntSignal
    
    wire IntClkDiv;
    wire IntClk;
    wire IntBitClkDone;
    
    wire AdcIntrfcRst = SysRst | (~IntBitClkDone);
    wire AdcIntrfcEna = 1     ;
    wire AdcReSync = 0       ;
    wire AdcIdlyCtrlRdy   ;
    
    wire IntDCLK_p;
    wire IntFCLK_p,IntFCLK_n;
    wire [(C_AdcChnls*C_AdcWireInt)-1 : 0] IntDATA_p;
    wire [(C_AdcChnls*C_AdcWireInt)-1 : 0] IntDATA_n;
    wire IntRst;
//    wire IntClk,IntClkDiv;
//    wire IntClk_90;
    wire IntEna_d;
    wire IntEna;


    
    IBUFGDS 
        #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS_25"))
    Inst_FCLK_IBUFDS
        (.I(FCLK_p_pin), .IB(FCLK_n_pin), .O(IntFCLK_p));
    genvar i;
    generate
        for (i = 0;i<(C_AdcChnls*C_AdcWireInt);i=i+1)
        begin
            IBUFDS 
                #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS_25"))
            Inst_DATA_IBUFDS
                (.I(DATA_p_pin[i]), .IB(DATA_n_pin[i]), .O(IntDATA_p[i]));
        end
    endgenerate   

    FDPE 
        #(.INIT(1))
    Inst_Fdpe_Rst
        (.C(IntClkDiv), .CE(1), .PRE(AdcIntrfcRst), .D(0), .Q(IntRst));

    FDCE 
        #(.INIT(1))
    Inst_Fdpe_Ena_0
        (.C(IntClkDiv), .CE(AdcIntrfcEna), .CLR(IntRst), .D(1), .Q(IntEna_d));
    FDCE 
        #(.INIT(1))
    Inst_Fdpe_Ena_1
        (.C(IntClkDiv), .CE(1), .CLR(IntRst), .D(IntEna_d), .Q(IntEna));
        
    // MMCM regenerate dclk
    MMCM_350M Inst_AdcDclk
       (
           // Clock in ports
          .clk_in1_p(DCLK_p_pin),
          .clk_in1_n(DCLK_n_pin),
            // Clock out ports
          .clk_out1(IntClk),
          .clk_out2(IntClkDiv),
            // Status and control signals
          .reset(0),
          .locked(IntBitClkDone)
       );
       
    // sample fclk
    wire IntBitslip;
    wire IntFrmAlignDone;
	AdcFrame #(
            .AdcBits(14),
            .FrmPattern(16'b0011111110000000)
        ) inst_AdcFrame (
            .FrmFCLK      (IntFCLK_p),
            .FrmClk       (IntClk),
            .FrmClkDiv    (IntClkDiv),
            .FrmRst       (IntRst),
            .BitClkDone   (IntBitClkDone),
            .FrmBitslip   (IntBitslip),
            .FrmAlignDone (IntFrmAlignDone)
        );


    wire [16*C_AdcChnls*C_AdcWireInt-1:0] DatData;
    wire [C_AdcChnls*C_AdcWireInt-1:0]IntDatAlignDone;
    // sample lanes
    generate
        for (i = 0;i<(C_AdcChnls*C_AdcWireInt);i=i+1)
        begin
        AdcLane #(
                .AdcBits(14)
            ) inst_AdcLane (
                .DatLine      (IntDATA_p[i]),
                .DatClk       (IntClk),
                .DatClkDiv    (IntClkDiv),
                .DatRst       (IntRst),
                .DatBitslip   (IntBitslip),
                .FrmAlignDone (IntFrmAlignDone),
                .DatData      (DatData[(i+1)*16-1:i*16]),
                .DatAlignDone (IntDatAlignDone[i])
            );
        end
    endgenerate    

    wire [16*C_AdcChnls*C_AdcWireInt-1:0] AdcData;
    
    // swap lane data to AdcData
    generate
        for (i = 0;i<(C_AdcChnls*C_AdcWireInt);i=i+2)
        begin
        AdcSwap #(
                .AdcBits(14),
                .AdcByteOrBitMode(1),
                .AdcMsbOrLsbFst(1),
                .AdcWireMode(1)
            ) inst_AdcSwap (
                .FrmClk    (IntClkDiv),
                .DataLine0 (DatData[(i+1)*16-1:i*16]),
                .DataLine1 (DatData[(i+2)*16-1:(i+1)*16]),
                .AdcData0  (AdcData[(i+1)*16-1:i*16]),
                .AdcData1  (AdcData[(i+2)*16-1:(i+1)*16])
            );
        end
    endgenerate

    assign AdcFrmClk = IntClkDiv;
    assign AdcDataValid = IntDatAlignDone;

    generate 
        if (C_AdcChnls == 1) begin
            assign AdcDataCh0 = AdcData[15:0];
        end else if (C_AdcChnls == 2) begin
            assign AdcDataCh0 = AdcData[15:0];
            assign AdcDataCh1 = AdcData[31:16];
        end else if (C_AdcChnls == 4) begin
            assign AdcDataCh0 = AdcData[15:0];
            assign AdcDataCh1 = AdcData[31:16];
            assign AdcDataCh2 = AdcData[47:32];
            assign AdcDataCh3 = AdcData[63:48];
        end else if (C_AdcChnls == 6) begin
            assign AdcDataCh0 = AdcData[15:0];
            assign AdcDataCh1 = AdcData[31:16];
            assign AdcDataCh2 = AdcData[47:32];
            assign AdcDataCh3 = AdcData[63:48];
            assign AdcDataCh4 = AdcData[79:64];
            assign AdcDataCh5 = AdcData[95:80];
        end else if (C_AdcChnls == 8) begin
            assign AdcDataCh0 = AdcData[15:0];
            assign AdcDataCh1 = AdcData[31:16];
            assign AdcDataCh2 = AdcData[47:32];
            assign AdcDataCh3 = AdcData[63:48];
            assign AdcDataCh4 = AdcData[79:64];
            assign AdcDataCh5 = AdcData[95:80];
            assign AdcDataCh6 = AdcData[111:96];
            assign AdcDataCh7 = AdcData[127:112];
        end
    endgenerate    
    
endmodule

module MMCM_350M 

 (// Clock in ports
  // Clock out ports
  output        clk_out1,
  output        clk_out2,
  // Status and control signals
  input         reset,
  output        locked,
  input         clk_in1_p,
  input         clk_in1_n
 );
  // Input buffering
  //------------------------------------
wire clk_in1_clk_wiz_0;
wire clk_in2_clk_wiz_0;
  IBUFDS clkin1_ibufgds
   (.O  (clk_in1_clk_wiz_0),
    .I  (clk_in1_p),
    .IB (clk_in1_n));




  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        clk_out1_clk_wiz_0;
  wire        clk_out2_clk_wiz_0;
  wire        clk_out3_clk_wiz_0;
  wire        clk_out4_clk_wiz_0;
  wire        clk_out5_clk_wiz_0;
  wire        clk_out6_clk_wiz_0;
  wire        clk_out7_clk_wiz_0;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_0;
  wire        clkfbout_buf_clk_wiz_0;
  wire        clkfboutb_unused;
    wire clkout0b_unused;
   wire clkout1b_unused;
   wire clkout2_unused;
   wire clkout2b_unused;
   wire clkout3_unused;
   wire clkout3b_unused;
   wire clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;
  wire        reset_high;

  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (3.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (3.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKOUT1_DIVIDE       (21),
    .CLKOUT1_PHASE        (00.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (2.857))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_0),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clk_out1_clk_wiz_0),
    .CLKOUT0B            (clkout0b_unused),
    .CLKOUT1             (clk_out2_clk_wiz_0),
    .CLKOUT1B            (clkout1b_unused),
    .CLKOUT2             (clkout2_unused),
    .CLKOUT2B            (clkout2b_unused),
    .CLKOUT3             (clkout3_unused),
    .CLKOUT3B            (clkout3b_unused),
    .CLKOUT4             (clkout4_unused),
    .CLKOUT5             (clkout5_unused),
    .CLKOUT6             (clkout6_unused),
     // Input clock control
    .CLKFBIN             (clkfbout_buf_clk_wiz_0),
    .CLKIN1              (clk_in1_clk_wiz_0),
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
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (reset_high));
  assign reset_high = reset; 

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG clkf_buf
   (.O (clkfbout_buf_clk_wiz_0),
    .I (clkfbout_clk_wiz_0));






  BUFG clkout1_buf
   (.O   (clk_out1),
    .I   (clk_out1_clk_wiz_0));


  BUFG clkout2_buf
   (.O   (clk_out2),
    .I   (clk_out2_clk_wiz_0));



endmodule
