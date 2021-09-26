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
    parameter C_AdcChnls = 4,     // Number of ADC in a package
    parameter C_AdcWireInt = 2,  // 2 = 2-wire, 1 = 1-wire interface
    parameter C_AdcBits = 12,
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
    
    output                  adc_pdn,
    output                  adc_reset,
    // ADC is Slave
//    inout                   spi_sdio,
    input                   spi_miso_i,
    output                  spi_mosi_o,
    output                  spi_clk,
    output                  spi_cs
);
    
    wire SysClk50M;
    
    wire SysRefClk        ;
    wire AdcIntrfcRst     ;
    wire AdcIntrfcEna     ;
    wire AdcReSync        ;
//    wire AdcFrmSyncWrn    ;
    wire AdcBitClkAlgnWrn ;
    wire AdcBitClkInvrtd  ;
//    wire AdcBitClkDone    ;
    wire AdcIdlyCtrlRdy   ;
   
    wire AdcFrmClk;
    wire [7:0] AdcDataValid;
    wire [15:0] AdcDataCh0;
    wire [15:0] AdcDataCh1;
    wire [15:0] AdcDataCh2;
    wire [15:0] AdcDataCh3;
    wire [15:0] AdcDataCh4;
    wire [15:0] AdcDataCh5;
    wire [15:0] AdcDataCh6;
    wire [15:0] AdcDataCh7;
    
    assign adc_pdn = 0;
    assign adc_reset = 0;
    
//    wire spi_mosi_o;
//    wire spi_miso_i;
    wire spi_tri_o;
    wire [7:0] spi_cs_o;
    
    assign spi_cs = spi_cs_o[0];

    wire AdcSampClk;
    // MMCM regenerate dclk
    MMCM Inst_SysClk
       (
            // Clock in ports
            .clk_in1_p (SysClk_p_pin    ),
            .clk_in1_n (SysClk_n_pin    ),
            // Clock out ports
            .clk_out1  (AdcSampClk      ),
            // Status and control signals
            .reset     (0             ),
            .locked    ( )
       );
    

    // AD3444
	AdcLVDS #(
            .AdcChnls(4),
            .AdcBits(14),
            .AdcBitOrByteMode(0),
            .AdcMsbOrLsbFst(0),
            .AdcWireMode(2),
            .AdcFrmPattern(16'b0011111110000000),
            .AdcSampFreDiv2(1)
            ) inst_AdcLVDS (
			.DCLK_p_pin   (DCLK_p_pin),
			.DCLK_n_pin   (DCLK_n_pin),
			.FCLK_p_pin   (FCLK_p_pin),
			.FCLK_n_pin   (FCLK_n_pin),
			.DATA_p_pin   (DATA_p_pin),
			.DATA_n_pin   (DATA_n_pin),
			.SysRst       (0),
			.AdcSampClk   (AdcSampClk),
			.AdcFrmClk    (AdcFrmClk),
			.AdcDataValid (AdcDataValid),
			.AdcDataCh0   (AdcDataCh0),
			.AdcDataCh1   (AdcDataCh1),
			.AdcDataCh2   (AdcDataCh2),
			.AdcDataCh3   (AdcDataCh3)
		);



/*
   // AD9252

   IOBUF 
       #(.DRIVE("12"), .SLEW("FAST"))
   Inst_spidio_IOBUF
       (.O(spi_miso_i), .IO(spi_sdio), .I(spi_mosi_o), .T(spi_tri_o));
	AdcLVDS #(
            .AdcChnls(8),
            .AdcBits(14),
            .AdcBitOrByteMode(1),
            .AdcMsbOrLsbFst(1),
            .AdcWireMode(1),
            .AdcFrmPattern(16'b0011111110000000),
            .AdcSampFreDiv2(0)
            ) inst_AdcLVDS (
			.DCLK_p_pin   (DCLK_p_pin),
			.DCLK_n_pin   (DCLK_n_pin),
			.FCLK_p_pin   (FCLK_p_pin),
			.FCLK_n_pin   (FCLK_n_pin),
			.DATA_p_pin   (DATA_p_pin),
			.DATA_n_pin   (DATA_n_pin),
			.SysRst       (0),
			.AdcSampClk   (),
			.AdcFrmClk    (AdcFrmClk),
			.AdcDataValid (AdcDataValid),
			.AdcDataCh0   (AdcDataCh0),
			.AdcDataCh1   (AdcDataCh1),
			.AdcDataCh2   (AdcDataCh2),
			.AdcDataCh3   (AdcDataCh3),
			.AdcDataCh4   (AdcDataCh4),
			.AdcDataCh5   (AdcDataCh5),
			.AdcDataCh6   (AdcDataCh6),
			.AdcDataCh7   (AdcDataCh7)
		);

*/
  
    wire BRAM_PORTA_0_clk = AdcFrmClk;
    wire BRAM_PORTA_1_clk = AdcFrmClk;
    wire BRAM_PORTA_2_clk = AdcFrmClk;
    wire BRAM_PORTA_3_clk = AdcFrmClk;
    wire BRAM_PORTA_4_clk = AdcFrmClk;
  
    reg   [13:0]  BRAM_PORTA_0_addr;
    reg   [0:0]   BRAM_PORTA_0_we   ;
    reg   [127:0] BRAM_PORTA_0_din;
    
    wire  [13:0]  BRAM_PORTA_1_addr = BRAM_PORTA_0_addr;
    wire  [0:0]   BRAM_PORTA_1_we   = BRAM_PORTA_0_we  ;
    reg   [127:0] BRAM_PORTA_1_din                     ;
    
    wire  [13:0]  BRAM_PORTA_2_addr = BRAM_PORTA_0_addr;
    wire  [0:0]   BRAM_PORTA_2_we   = BRAM_PORTA_0_we  ;
    reg   [127:0] BRAM_PORTA_2_din                     ;
    
    wire  [13:0]  BRAM_PORTA_3_addr = BRAM_PORTA_0_addr;
    wire  [0:0]   BRAM_PORTA_3_we   = BRAM_PORTA_0_we  ;
    reg   [127:0] BRAM_PORTA_3_din                     ;
    
    wire  [13:0]  BRAM_PORTA_4_addr = BRAM_PORTA_0_addr;
    wire  [0:0]   BRAM_PORTA_4_we   = BRAM_PORTA_0_we  ;
    reg   [127:0] BRAM_PORTA_4_din                     ;


    wire [8*16-1:0] AD_Data = {AdcDataCh7, AdcDataCh6, AdcDataCh5, AdcDataCh4, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
//    wire [8*16-1:0] AD_Data_2 = {8{{6{Cos_10_7[13]}},Cos_10_7[12:3]}};
    ila_0 Inst_ila
        (
            .clk(AdcFrmClk),
            .probe0(spi_miso_i),
            .probe1(spi_mosi_o),
            .probe2(spi_clk),
            .probe3(spi_cs_o),
            .probe4(AdcDataCh0),
            .probe5(AdcDataCh1),
            .probe6(AdcDataCh2),
            .probe7(AdcDataCh3)
        );
  reg In0_0;
  wire In1_0;
  wire [31:0] gpio_io_o_0;
  reg [1:0] gpio_posedge_0;
  reg [1:0] gpio_posedge_1;
  always @ (posedge AdcFrmClk) begin
      gpio_posedge_0 <= {gpio_posedge_0[0], gpio_io_o_0[31]};
      gpio_posedge_1 <= {gpio_posedge_1[0], gpio_io_o_0[30]};
  end
  
//  always @ (posedge AdcFrmClk) begin
//      if (gpio_posedge_1 == 2'b01) begin
////          shift_trunc <= gpio_io_o_0[28:24];
////          if (shift_trunc == 5'd23) begin
////            shift_trunc <= 5'd0;
////          end else begin
////            shift_trunc <= shift_trunc + 1'b1;
////          end
//      end
//  end
  
  reg [3:0] cap_state; 
  always @ (posedge AdcFrmClk) begin
      if (AdcDataValid[0] == 1'b0) begin
        BRAM_PORTA_0_we <= 1'b0;
        BRAM_PORTA_0_addr <= 14'd0;
        BRAM_PORTA_0_din <= 128'd0;
        
        BRAM_PORTA_1_din <= 128'd0;
        BRAM_PORTA_2_din <= 128'd0;
        BRAM_PORTA_3_din <= 128'd0;
        BRAM_PORTA_4_din <= 128'd0;
        
        cap_state <= 4'd0;
        In0_0 <= 1'b0;
      end else begin
        case(cap_state)
        4'd0: begin
          if (gpio_posedge_0 == 2'b01) begin
              BRAM_PORTA_0_we <= 1'b1;
              BRAM_PORTA_0_addr <= 14'd0;
              BRAM_PORTA_0_din = {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
//              BRAM_PORTA_0_din <= {AdcDataCh7, {6{2'b00, BRAM_PORTA_0_addr}}, AdcDataCh0};

                BRAM_PORTA_1_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                BRAM_PORTA_2_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                BRAM_PORTA_3_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                BRAM_PORTA_4_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
              cap_state <= 4'd1;
            end else begin
              BRAM_PORTA_0_we <= 1'b0;
              BRAM_PORTA_0_addr <= 14'd0;
              BRAM_PORTA_0_din <= 128'd0;
              cap_state <= 4'd0;
            end 
            In0_0 <= 1'b0;
        end
        4'd1: begin
            if (BRAM_PORTA_0_addr == gpio_io_o_0[13:0]) begin
                BRAM_PORTA_0_we <= 1'b0;
                BRAM_PORTA_0_addr <= 14'd0;
                BRAM_PORTA_0_din <= 128'd0;
                cap_state <= 4'd2;
            end else begin
                BRAM_PORTA_0_we <= 1'b1;
                BRAM_PORTA_0_addr <= BRAM_PORTA_0_addr + 1'b1;
              BRAM_PORTA_0_din = {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
  //              BRAM_PORTA_0_din <= {AdcDataCh7, {6{2'b00, BRAM_PORTA_0_addr}}, AdcDataCh0};
  
                  BRAM_PORTA_1_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                  BRAM_PORTA_2_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                  BRAM_PORTA_3_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};
                  BRAM_PORTA_4_din <= {16'd0, 16'd0, 16'd0, 16'd0, AdcDataCh3, AdcDataCh2, AdcDataCh1, AdcDataCh0};

                cap_state <= 4'd1;
            end 
            In0_0 <= 1'b0;
        end
        4'd2: begin
            BRAM_PORTA_0_we <= 1'b0;
            BRAM_PORTA_0_addr <= 14'd0;
            BRAM_PORTA_0_din <= 128'd0;
            
            BRAM_PORTA_1_din <= 128'd0;
            BRAM_PORTA_2_din <= 128'd0;
            BRAM_PORTA_3_din <= 128'd0;
            BRAM_PORTA_4_din <= 128'd0;
            
            cap_state <= 4'd0;
            In0_0 <= 1'b1;
        end
        default:;
        endcase
      end 
  end
  
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

            .BRAM_PORTA_0_addr(BRAM_PORTA_0_addr),
            .BRAM_PORTA_0_clk(BRAM_PORTA_0_clk),
            .BRAM_PORTA_0_din(BRAM_PORTA_0_din),
            .BRAM_PORTA_0_we(BRAM_PORTA_0_we),
            .BRAM_PORTA_1_addr(BRAM_PORTA_1_addr),
            .BRAM_PORTA_1_clk(BRAM_PORTA_1_clk),
            .BRAM_PORTA_1_din(BRAM_PORTA_1_din),
            .BRAM_PORTA_1_we(BRAM_PORTA_1_we),
            .BRAM_PORTA_2_addr(BRAM_PORTA_2_addr),
            .BRAM_PORTA_2_clk(BRAM_PORTA_2_clk),
            .BRAM_PORTA_2_din(BRAM_PORTA_2_din),
            .BRAM_PORTA_2_we(BRAM_PORTA_2_we),
            .BRAM_PORTA_3_addr(BRAM_PORTA_3_addr),
            .BRAM_PORTA_3_clk(BRAM_PORTA_3_clk),
            .BRAM_PORTA_3_din(BRAM_PORTA_3_din),
            .BRAM_PORTA_3_we(BRAM_PORTA_3_we),
            .BRAM_PORTA_4_addr(BRAM_PORTA_4_addr),
            .BRAM_PORTA_4_clk(BRAM_PORTA_4_clk),
            .BRAM_PORTA_4_din(BRAM_PORTA_4_din),
            .BRAM_PORTA_4_we(BRAM_PORTA_4_we),
            
            .In0_0(In0_0),
            .In1_0(In1_0),
            .gpio_io_o_0(gpio_io_o_0),
            
          .spi_miso_i_0(spi_miso_i),
          .spi_mosi_o_0(spi_mosi_o),
          .spi_clk_o_0(spi_clk),
          .spi_cs_o_0(spi_cs_o),
          .spi_tri_o_0(spi_tri_o)
          );
endmodule

//(* CORE_GENERATION_INFO = "dcm,clk_wiz_v3_6,{component_name=dcm,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,feedback_source=FDBK_AUTO,primtype_sel=MMCM_ADV,num_out_clk=1,clkin1_period=8.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=true,use_inclk_stopped=false,use_status=false,use_freeze=false,use_clk_valid=false,feedback_type=SINGLE,clock_mgr_type=MANUAL,manual_override=false}" *)
module MMCM

 (// Clock in ports
  // Clock out ports
  output        clk_out1,
  output        clk_out2,
  output        clk_out1b,
  output        clk_out2b,
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
  wire        clk_out1_clk_wiz_0b;
  wire        clk_out2_clk_wiz_0b;
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
    .CLKFBOUT_MULT_F      (10.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (10.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKOUT1_DIVIDE       (21),
    .CLKOUT1_PHASE        (00.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (10))
  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_0),
    .CLKFBOUTB           (clkfboutb_unused),
    .CLKOUT0             (clk_out1_clk_wiz_0),
    .CLKOUT0B            (clk_out1_clk_wiz_0b),
    .CLKOUT1             (clk_out2_clk_wiz_0),
    .CLKOUT1B            (clk_out2_clk_wiz_0b),
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


  BUFG clkout1_bufb
   (.O   (clk_out1b),
    .I   (clk_out1_clk_wiz_0b));


  BUFG clkout2_bufb
   (.O   (clk_out2b),
    .I   (clk_out2_clk_wiz_0b));

endmodule

