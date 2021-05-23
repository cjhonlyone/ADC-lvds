`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/21 18:36:01
// Design Name: 
// Module Name: AdcSwap
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

module AdcSwap #(
    parameter AdcBits = 14,
    parameter AdcByteOrBitMode = 1, // 1 = BIT mode, 0 = BYTE mode
    parameter AdcMsbOrLsbFst = 1, // 0 = MSB first, 1 = LSB first
    parameter AdcWireMode = 1 // 1 = 1-wire, 2 = 2-wire
)
(
    input FrmClk,
    
    input [15:0] DataLine0,
    input [15:0] DataLine1,
    
    output [15:0] AdcData0,
    output [15:0] AdcData1
    
);
    assign AdcData0 = DataLine0;
    assign AdcData1 = DataLine1;

endmodule
