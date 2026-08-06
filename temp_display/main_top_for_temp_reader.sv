`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 05:21:56 PM
// Design Name: 
// Module Name: main_top_for_temp_reader
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


module main_top_for_temp_reader#(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000,
    parameter integer FIRST_READ_DELAY = 1_000_000,
    parameter integer READ_INTERVAL = 24_000_000
)(

    input  logic clk,
    input  logic rst,

    inout wire TMP_SDA,
    output logic scl_out,

    output logic [6:0] seg,
    output logic [7:0] an,
    output logic decimal_point
    );

    
    logic [15:0] temperature_raw;

    logic [7:0] temp_celsius;
    logic [3:0] temp_fraction;

    logic data_valid;
    logic ack_error;

   
    logic [3:0] tens;
    logic [3:0] ones;
    logic [3:0] fraction;

    logic [3:0] digit;

    logic [1:0] sel;

    logic sda_in; // valoarea citita de master
    logic sda_out; // valoarea transmisa de master
    logic sda_t; // controlul directiei bufferului
    
    assign sda_t = sda_out;
    
    IOBUF TMP_SDA_BUF (
    .I (1'b0),        // valoarea care se conduce pe pin
    .O (sda_in),      // valoarea citită de pe pin
    .IO(TMP_SDA),     // pinul fizic
    .T (sda_t)        // 1 = Hi sau Z, 0 = conduce valoarea I
    );
    
    
    
    temp_controller#(
    .CLK_FREQ(CLK_FREQ),
    .I2C_FREQ(I2C_FREQ),
    .FIRST_READ_DELAY(FIRST_READ_DELAY),
    .READ_INTERVAL(READ_INTERVAL)
    ) TEMP_CONTROLLER(

        .clk(clk),
        .rst(rst),

        .sda_in(sda_in),
        .sda_out(sda_out),
        .scl_out(scl_out),

        .temperature_raw(temperature_raw),

        .data_valid(data_valid),
        .ack_error(ack_error)

    );

    temp_converter TEMP_CONVERTER(

        .temperature_raw(temperature_raw),
        .temp_celsius(temp_celsius),
        .temp_fraction(temp_fraction)

    );

   
    b2d TEMP_TO_DIGITS(

        .temp_celsius(temp_celsius),
        .temp_fraction(temp_fraction),
        .tens(tens),
        .ones(ones),
        .fraction(fraction)

    );

    
    refresh REFRESH(

        .clk(clk),
        .sel(sel)

    );


    mux MUX(

        .sel(sel),
        .tens(tens),
        .ones(ones),
        .fraction(fraction),
        .digit(digit)

    );


    seg_dec SEG_DEC(

        .digit(digit),
        .seg(seg)

    );

   
    anode_selector ANODE_SELECTOR(

        .sel(sel),
        .an(an)

    );
    
    always @(*)
    begin
        if(sel == 2'd2)
            decimal_point = 1'b0;
        else
            decimal_point = 1'b1;
    end
    
endmodule
