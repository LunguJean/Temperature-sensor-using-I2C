`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 04:56:04 PM
// Design Name: 
// Module Name: b2d
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


    

module b2d(
    input  logic [7:0] temp_celsius,
    input logic [3:0] temp_fraction,
    
    output logic [3:0] tens,
    output logic [3:0] ones,
    output logic [3:0] fraction
);

    

    always @(*)
    begin
        ones = temp_celsius % 8'd10;
        tens = temp_celsius / 8'd10;
        fraction = temp_fraction;

    end


endmodule
