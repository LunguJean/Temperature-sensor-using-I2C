`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 05:12:43 PM
// Design Name: 
// Module Name: anode_selector
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

module anode_selector(
    input logic [1:0] sel,
    output logic [7:0] an
);

    always @(*) 
    begin
        case(sel)
            2'd0: an = 8'b11111110; //AN0
            2'd1: an = 8'b11111101; //AN1
            2'd2: an = 8'b11111011; //AN2
            2'd3: an = 8'b11110111; //AN3
            default: an = 8'b11111111;
        endcase
    end

endmodule
 


