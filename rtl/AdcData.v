`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/09 15:32:32
// Design Name: 
// Module Name: AdcData
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


module AdcData(
    input DatLine0     ,
    input DatLine1     ,
    input DatClk       ,
    input DatClkDiv    ,
    input DatRst       ,
    input DatBitslip   ,
    input FrmAlignDone ,
    output [15:0] DatData0     ,
    output [15:0] DatData1     ,
    output DatAlignDone
    );
    wire [13:0] ADCDataLine0;
    wire [13:0] ADCDataLine1;
    
    reg [13:0] ADCData0;
    reg [13:0] ADCData1;
    Serdes_1x14_DDR inst_Serdes_1x14_DDR_Data_Line0
     (
         .CLK     (DatClk),
         .CLKDIV  (DatClkDiv),
         .BITSLIP (DatBitslip),
         .CE1     (1),
         .CE2     (1),
         .D       (DatLine0),
         .DDLY    (DatLine0),
         .RST     (DatRst),
         .Q       (ADCDataLine0)
     );
     Serdes_1x14_DDR inst_Serdes_1x14_DDR_Data_Line1
     (
         .CLK     (DatClk),
         .CLKDIV  (DatClkDiv),
         .BITSLIP (DatBitslip),
         .CE1     (1),
         .CE2     (1),
         .D       (DatLine1),
         .DDLY    (DatLine1),
         .RST     (DatRst),
         .Q       (ADCDataLine1)
     );

     always @ (posedge DatClkDiv) begin
//         ADCData0 <= {ADCDataLine1[7],ADCDataLine1[8],ADCDataLine1[9],ADCDataLine1[10],ADCDataLine1[11],ADCDataLine1[12],ADCDataLine1[13],
//                     ADCDataLine0[7],ADCDataLine0[8],ADCDataLine0[9],ADCDataLine0[10],ADCDataLine0[11],ADCDataLine0[12],ADCDataLine0[13]};
//         ADCData1 <= {ADCDataLine1[0],ADCDataLine1[1],ADCDataLine1[2],ADCDataLine1[3],ADCDataLine1[4],ADCDataLine1[5],ADCDataLine1[6],
//                     ADCDataLine0[0],ADCDataLine0[1],ADCDataLine0[2],ADCDataLine0[3],ADCDataLine0[4],ADCDataLine0[5],ADCDataLine0[6]};
         ADCData0 <= ADCDataLine0;
         ADCData1 <= ADCDataLine0;
     end
     
     assign DatData0 = {ADCData0[13],ADCData0[13],ADCData0};
     assign DatData1 = {ADCData1[13],ADCData1[13],ADCData1};
     
     assign DatAlignDone = FrmAlignDone;
     
endmodule
