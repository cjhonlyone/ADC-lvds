`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 14:49:16
// Design Name: 
// Module Name: ADC3444_Top
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


module ADC344x_Top # (
    parameter C_AdcChnls = 2,     // Number of ADC in a package
    parameter C_AdcWireInt = 2    // 2 = 2-wire, 1 = 1-wire interface
)
(
    input DCLK_p_pin,
    input DCLK_n_pin,
    input FCLK_p_pin,
    input FCLK_n_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_p_pin,
    input [(C_AdcChnls*C_AdcWireInt)-1 : 0] DATA_n_pin,
    
    input SysDlyClk,
    input SysRst,
    
    input SysSampleClk, // when 2 wires mode equal to 2x FCLK
    input SysSampleRst,
    output AdcDataValid,
    output [15:0] AdcDataCh0,
    output [15:0] AdcDataCh1,
    output [15:0] AdcDataCh2,
    output [15:0] AdcDataCh3,

    output ADC_SCLK,
    input  ADC_MISO,
    output ADC_CS,
    output ADC_MOSI,
    output ADC_PDN,
    output ADC_RESET
    );
    
    assign ADC_PDN = 0;
    assign ADC_RESET = SysRst;

    // Pin to IntSignal
    wire AdcIntrfcRst = SysRst   ;
    wire AdcIntrfcEna = 1     ;
    wire AdcReSync = 0       ;
    wire AdcIdlyCtrlRdy   ;
    
    wire IntDCLK_p;
    wire IntFCLK_p,IntFCLK_n;
    wire [(C_AdcChnls*C_AdcWireInt)-1 : 0] IntDATA_p;
    wire [(C_AdcChnls*C_AdcWireInt)-1 : 0] IntDATA_n;
    wire IntRst;
    wire IntClk,IntClkDiv;
    wire IntEna_d;
    wire IntEna;
    
    IBUFGDS 
        #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS_25"))
    Inst_DCLK_IBUFGDS
        (.I(DCLK_p_pin), .IB(DCLK_n_pin), .O(IntDCLK_p));
    IBUFGDS 
        #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS_25"))
    Inst_FCLK_IBUFDS
        (.I(FCLK_p_pin), .IB(FCLK_n_pin), .O(IntFCLK_p));
    genvar i;
    generate
        for (i = 0;i<(C_AdcChnls*C_AdcWireInt);i=i+1)
        begin
            IBUFGDS 
                #(.DIFF_TERM("TRUE"), .IOSTANDARD("LVDS_25"))
            Inst_DATA_IBUFDS
                (.I(DATA_p_pin[i]), .IB(DATA_n_pin[i]), .O(IntDATA_p[i]));
        end
    endgenerate     
    
    IDELAYCTRL 
    Inst_IDELAYCTRL
        (.REFCLK(SysDlyClk), .RST(AdcIntrfcRst), .RDY(AdcIdlyCtrlRdy));
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
    
    // Bit Clock Alignment
    wire AdcBitClkAlgnWrn ;
    wire AdcBitClkInvrtd  ;
    wire IntBitClkDone;
    AdcClock #
         (
             .C_BufioLoc ("BUFIO_X0Y7"),
             .C_BufrLoc  ("BUFR_X0Y7"),
             .C_AdcBits  (14),
             .C_StatTaps (16)
         )
     Inst_AdcClock
         (
             .BitClk           (IntDCLK_p),            // in
             .BitClkRst        (IntRst),               // in
             .BitClkEna        (IntEna),               // in
             .BitClkReSync     (AdcReSync),            // in
             .BitClk_MonClkOut (IntClk),               // out  -->--|---->----
             .BitClk_MonClkIn  (IntClk),               // in   --<--|
             .BitClk_RefClkOut (IntClkDiv),            // out  -->----|-->----
             .BitClk_RefClkIn  (IntClkDiv),            // in   --<----|
             .BitClkAlignWarn  (AdcBitClkAlgnWrn),     // out
             .BitClkInvrtd     (AdcBitClkInvrtd),      // out
             .BitClkDone       (IntBitClkDone)         // out Enables the AdcFrame block.
         );
         
    // Frame Alignment
    wire IntBitslip;
    wire IntFrmAlignDone;
    AdcFrame
    Inst_AdcFrame
        (
            .FrmFCLK      (IntFCLK_p     ),
            .FrmClk       (IntClk        ),
            .FrmClkDiv    (IntClkDiv     ),
            .FrmRst       (IntRst        ),
            .BitClkDone   (IntBitClkDone ),
            .FrmBitslip   (IntBitslip    ),
            .FrmAlignDone (IntFrmAlignDone  )
        );
        
    wire [16*C_AdcChnls*2-1:0] AdcData;
    // Data Swap
    wire [C_AdcChnls-1:0]IntDatAlignDone;
    
    generate
        for (i = 0;i<(C_AdcChnls);i=i+1)
        begin
        AdcData
            Inst_AdcData
            (
                .DatLine0     (IntDATA_p[i*2 + 0]             ),
                .DatLine1     (IntDATA_p[i*2 + 1]             ),
                .DatClk       (IntClk                         ),
                .DatClkDiv    (IntClkDiv                      ),
                .DatRst       (IntRst                         ),
                .DatBitslip   (IntBitslip                     ),
                .FrmAlignDone (IntFrmAlignDone                ),
                .DatData0     (AdcData[i*16+16-1:i*16]        ),
                .DatData1     (AdcData[i*16+16-1+C_AdcChnls*16:i*16+C_AdcChnls*16]  ),
                .DatAlignDone (IntDatAlignDone[i]             )
            );
        end
    endgenerate     

    wire s_axis_tready;
    wire [16*C_AdcChnls-1:0] AdcData2x1;
    wire m_axis_tvalid;
    wire [C_AdcChnls*2-1:0] m_axis_tkeep;
    // 2x 50MHz to 1x 100MHz
    axis_async_fifo_adapter #(
        .DEPTH(4096),
        .S_DATA_WIDTH(16*C_AdcChnls*2),
        .M_DATA_WIDTH(16*C_AdcChnls),
        .ID_ENABLE(0),
        .ID_WIDTH(8),
        .DEST_ENABLE(0),
        .DEST_WIDTH(8),
        .USER_ENABLE(0),
        .USER_WIDTH(8),
        .FRAME_FIFO(0),
        .USER_BAD_FRAME_VALUE(1'b1),
        .USER_BAD_FRAME_MASK(1'b1),
        .DROP_BAD_FRAME(0),
        .DROP_WHEN_FULL(0)
    )
    Inst_async_fifo (
        // AXI input
        .s_clk(IntClkDiv),
        .s_rst(IntRst),
        .s_axis_tdata (AdcData),
        .s_axis_tkeep ({C_AdcChnls*8{1'b1}}),
        .s_axis_tvalid(IntDatAlignDone[0]),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast (0 ),
        // .s_axis_tid(s_axis_tid),
        // .s_axis_tdest(s_axis_tdest),
        // .s_axis_tuser(s_axis_tuser),
        // AXI output
        .m_clk(SysSampleClk),
        .m_rst(SysSampleRst),
        .m_axis_tdata (AdcData2x1),
        .m_axis_tkeep (m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(1),
        .m_axis_tlast (),
        // .m_axis_tid(m_axis_tid),
        // .m_axis_tdest(m_axis_tdest),
        // .m_axis_tuser(m_axis_tuser),
        // Status
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );
    
    generate 
        if (C_AdcChnls == 1) begin
            assign AdcDataCh0 = AdcData2x1[15:0];
        end else if (C_AdcChnls == 2) begin
            assign AdcDataCh0 = AdcData2x1[15:0];
            assign AdcDataCh1 = AdcData2x1[31:16];
        end else if (C_AdcChnls == 3) begin
            assign AdcDataCh0 = AdcData2x1[15:0];
            assign AdcDataCh1 = AdcData2x1[31:16];
            assign AdcDataCh2 = AdcData2x1[47:32];
        end else if (C_AdcChnls == 4) begin
        
            assign AdcDataCh0 = AdcData2x1[15:0];
            assign AdcDataCh1 = AdcData2x1[31:16];
            assign AdcDataCh2 = AdcData2x1[47:32];
            assign AdcDataCh3 = AdcData2x1[63:48];
        end 
    endgenerate    
    
    assign AdcDataValid = IntDatAlignDone[0];
     
endmodule
