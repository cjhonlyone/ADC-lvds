`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 15:21:11
// Design Name: 
// Module Name: AdcFrame
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


module AdcFrame#(
    parameter AdcBits = 14,
    parameter FrmPattern = 16'b0011111110000000
)
(
    input FrmFCLK,
    input FrmClk,
    input FrmClkDiv,
    input FrmRst,
    input BitClkDone,
    output FrmBitslip,
    output FrmAlignDone
);
    
    wire [15:0] wFrmPattern;
    
    reg rFrmBitslip;
    reg [2:0] rBitslipCnt;
    reg rFrmAlignDone;
   
    generate 
    
        if (AdcBits == 14) begin
            Serdes_1x14_DDR inst_Serdes_1x14_DDR_Data_Line
             (
                 .CLK     (FrmClk),
                 .CLKDIV  (FrmClkDiv),
                 .BITSLIP (rFrmBitslip),
                 .D       (FrmFCLK),
                 .DDLY    (FrmFCLK),
                 .RST     (FrmRst),
                 .Q       (wFrmPattern[AdcBits-1:0])
             );
        end else if (AdcBits == 12) begin
            Serdes_1x12_DDR inst_Serdes_1x12_DDR_Data_Line
             (
                 .CLKP    (FrmClk),
                 .CLKN    (~FrmClk),
                 .CLKDIV  (FrmClkDiv),
                 .BITSLIP (rFrmBitslip),
                 .D       (FrmFCLK),
                 .DDLY    (FrmFCLK),
                 .RST     (FrmRst),
                 .Q       (wFrmPattern[AdcBits-1:0])
             );
        end else if (AdcBits == 10) begin
            Serdes_1x10_DDR inst_Serdes_1x10_DDR_Data_Line
             (
                 .CLK     (FrmClk),
                 .CLKDIV  (FrmClkDiv),
                 .BITSLIP (rFrmBitslip),
                 .D       (FrmFCLK),
                 .DDLY    (FrmFCLK),
                 .RST     (FrmRst),
                 .Q       (wFrmPattern[AdcBits-1:0])
             );
        end else if (AdcBits == 8) begin
            Serdes_1x8_DDR inst_Serdes_1x8_DDR_Data_Line
             (
                 .CLK     (FrmClk),
                 .CLKDIV  (FrmClkDiv),
                 .BITSLIP (rFrmBitslip),
                 .D       (FrmFCLK),
                 .DDLY    (FrmFCLK),
                 .RST     (FrmRst),
                 .Q       (wFrmPattern[AdcBits-1:0])
             );
        end
    
    endgenerate

    always @(posedge FrmClkDiv) begin
        if ((FrmRst == 1) || (BitClkDone == 0))begin
            rFrmBitslip <= 0;
            rBitslipCnt <= 0;
            rFrmAlignDone <= 0;
        end else begin
            if (rBitslipCnt == 4) begin
                rBitslipCnt <= 0;
                rFrmBitslip <= 0;
                rFrmAlignDone <= rFrmAlignDone;
            end else if (rBitslipCnt == 0) begin
                rBitslipCnt <= rBitslipCnt + 1;
                if (wFrmPattern[AdcBits-1:0] == FrmPattern[AdcBits-1:0]) begin
                    rFrmAlignDone <= 1;
                    rFrmBitslip <= 0;
                end else begin
                    rFrmAlignDone <= 0;
                    rFrmBitslip <= 1;
                end
            end else begin
                rBitslipCnt <= rBitslipCnt + 1;
                rFrmBitslip <= 0;
                rFrmAlignDone <= rFrmAlignDone;
            end
        end
    end
    
    assign FrmBitslip = rFrmBitslip;
    assign FrmAlignDone = rFrmAlignDone;
    
endmodule
