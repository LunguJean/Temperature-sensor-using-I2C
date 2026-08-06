`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 05:08:56 PM
// Design Name: 
// Module Name: mux
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


module mux(
    input logic [1:0] sel,

    input logic [3:0] ones,
    input logic [3:0] tens,
    input logic [3:0] fraction,
    output logic [3:0] digit
    );
    
    localparam logic [3:0] C = 4'hA;
    
    always @(*)
    begin
      case(sel)
        2'd0: digit = C; //AN0
        2'd1: digit = fraction; //AN1
        2'd2: digit = ones; //AN2
        2'd3: digit = tens; //AN3
        default: digit = 4'd0;
      endcase
    end

endmodule
