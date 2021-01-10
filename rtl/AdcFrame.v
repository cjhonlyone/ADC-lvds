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


module AdcFrame(
    input FrmFCLK,
    input FrmClk,
    input FrmClkDiv,
    input FrmRst,
    input BitClkDone,
    output FrmBitslip,
    output FrmAlignDone
    );
    
    wire [13:0] wFrmPattern;
    reg rFrmBitslip;
    reg [2:0] rBitslipCnt;
    reg rFrmAlignDone;
    
    Serdes_1x14_DDR inst_Serdes_1x14_DDR_FCLK
    (
        .CLK     (FrmClk),
        .CLKDIV  (FrmClkDiv),
        .BITSLIP (rFrmBitslip),
        .CE1     (1),
        .CE2     (1),
        .D       (FrmFCLK),
        .DDLY    (FrmFCLK),
        .RST     (FrmRst),
        .Q       (wFrmPattern)
    );
    
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
                if (wFrmPattern == 14'b11111110000000) begin
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
