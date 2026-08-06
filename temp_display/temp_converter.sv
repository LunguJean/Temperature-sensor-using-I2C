`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 04:13:42 PM
// Design Name: 
// Module Name: temp_converter
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


module temp_converter (
    input  logic [15:0] temperature_raw,
    input  logic data_valid_in,

    output logic [7:0] temp_celsius,
    output logic [3:0] temp_fraction,
    output logic data_valid_out
);

    
    always_comb begin
        temp_celsius = temperature_raw[15:7];
        temp_fraction = (temperature_raw[6:3] * 10) >> 4;
    end

    
    assign data_valid_out = data_valid_in;


endmodule
