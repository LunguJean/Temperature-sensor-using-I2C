`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 05:05:36 PM
// Design Name: 
// Module Name: seg_dec
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
////////////////////////////////////////////////////////////////////////////////

module seg_dec(
    input  logic [3:0] digit,
    output logic [6:0] seg
);

    localparam logic [3:0] C = 4'hA;

    always @(*)
        begin
            case(digit)
                4'd0: seg = 7'b0111111;
                4'd1: seg = 7'b0000110;
                4'd2: seg = 7'b1011011;
                4'd3: seg = 7'b1001111;
                4'd4: seg = 7'b1100110;
                4'd5: seg = 7'b1101101;
                4'd6: seg = 7'b1111101;
                4'd7: seg = 7'b0000111;
                4'd8: seg = 7'b1111111;
                4'd9: seg = 7'b1101111;
                C : seg = 7'b1100001;
                default: seg = 7'b0000000;
            endcase
            
          seg = ~seg;
        end



endmodule
