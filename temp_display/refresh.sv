`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 05:18:29 PM
// Design Name: 
// Module Name: refresh
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

module refresh(
        input logic clk,
        output logic [1:0] sel
    );
    
    logic [15:0] refresh_counter;
    
    always @(posedge clk)
    begin
           refresh_counter <= refresh_counter + 1'b1;
    end
    
    assign sel = refresh_counter[15:14];
    
endmodule
