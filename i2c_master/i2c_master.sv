`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2026 06:19:58 PM
// Design Name: 
// Module Name: i2c_master
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


module i2c_master#(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000
                
)(
    input logic clk,
    input logic rst, 
    
    input logic cmd_valid,
    input logic [2:0] cmd,
    
    input logic [7:0] tx_data,
    
    input logic nack,
    
    output logic [7:0] rx_data,
    output logic busy,
    output logic done,
    output logic ack,
    
    inout wire i2c_scl,
    inout wire i2c_sda
    );
    
    
    localparam logic [2:0] CMD_START = 3'b000;
    localparam logic [2:0] CMD_WRITE = 3'b001;
    localparam logic [2:0] CMD_READ  = 3'b010;
    localparam logic [2:0] CMD_STOP  = 3'b011;
    
    localparam integer HALF_PERIOD = CLK_FREQ / (2*I2C_FREQ);
    localparam integer LUNGIME_COUNTER = $clog2(HALF_PERIOD);
    
    logic [LUNGIME_COUNTER - 1:0] half_counter;
    
     
       localparam logic [4:0] IDLE = 5'd0;

       localparam logic [4:0] START = 5'd1;
       localparam logic [4:0] START_SDA = 5'd2;
       localparam logic [4:0] START_DONE = 5'd3;

       localparam logic [4:0] WRITE_BIT = 5'd4;
       localparam logic [4:0] WRITE_HIGH = 5'd5;
       localparam logic [4:0] WRITE_LOW = 5'd6;

       localparam logic [4:0] WAIT_ACK = 5'd7;
       localparam logic [4:0] ACK_HIGH = 5'd8;
       localparam logic [4:0] READ_ACK = 5'd9;
       localparam logic [4:0] ACK_LOW = 5'd10;

       localparam logic [4:0] READ_BIT = 5'd11;
       localparam logic [4:0] READ_HIGH = 5'd12;
       localparam logic [4:0] READ_DATA = 5'd13;
       localparam logic [4:0] READ_LOW = 5'd14;

       localparam logic [4:0] SEND_ACK = 5'd15;
       localparam logic [4:0] SEND_ACK_HIGH = 5'd16;
       localparam logic [4:0] SEND_ACK_LOW = 5'd17;

       localparam logic [4:0] STOP = 5'd18;
       localparam logic [4:0] STOP_HIGH = 5'd19;
       localparam logic [4:0] STOP_DONE = 5'd20;

       localparam logic [4:0] DONE = 5'd21;
       
       logic [4:0] state; 
       
       logic [7:0] tx;
       logic [7:0] rx;
       
       logic [2:0] bit_count;
       logic read_nack_reg;
       
       
       
       //iesiri open-drain pentru evitarea conflictelor
       logic sda_low;
       logic scl_low;

       logic sda_in;
       

       assign i2c_sda = sda_low ? 1'b0 : 1'bz;
       assign i2c_scl = scl_low ? 1'b0 : 1'bz;

       assign sda_in = i2c_sda;
       
       
       always @(posedge clk)
       begin
            if(rst)
            begin
                state <= IDLE;
                half_counter <= '0;
                sda_low <= 1'b0;
                scl_low <= 1'b0;
                
                tx <= 8'h00;
                rx <= 8'h00;
                rx_data <= 8'h00; 
                
                bit_count <= 3'd7;
                read_nack_reg <= 1'b1;
                
                busy <= 1'b0;
                done <= 1'b0;
                ack <= 1'b0;
            end
            else
            begin
                done <= 1'b0;
                
                if(state == IDLE) 
                begin
                    half_counter <= '0;
                    busy <= 1'b0;
                    
                    if(cmd_valid)
                    begin
                        busy <= 1'b1;
                        
                        case (cmd)
                        
                            CMD_START:
                            begin
                                
                                scl_low <= 1'b1;
                                sda_low <= 1'b0;
                                state <= START;
                                
                            end
                            
                            CMD_WRITE:
                            begin
                            
                                tx <= tx_data;
                                bit_count <= 3'd7;
                                scl_low <= 1'b1;
                                
                                if(tx_data[7] == 1'b0)
                                    sda_low <= 1'b1;
                                else
                                    sda_low <= 1'b0;
                                
                                state <= WRITE_BIT; 
                            end
                            
                            CMD_READ:
                            begin
                                
                                rx <= 8'h00;
                                bit_count <= 3'd7;
                                read_nack_reg <= nack;
                                
                                scl_low <= 1'b1;
                                sda_low <= 1'b0;
                                
                                state <= READ_BIT;
                                
                                
                            end
                            
                            CMD_STOP:
                            begin
                                
                                scl_low <= 1'b1;
                                sda_low <= 1'b1;
                                
                                state <= STOP;
                                
                            end
                            
                            default:
                            begin 
                                state <= DONE;
                            end
                        endcase
                    end
                end
                
                else if(state == DONE)
                    begin
                    
                        busy <= 1'b0;
                        done <= 1'b1;
                        half_counter <= '0;
                        state <= IDLE;
                        
                    end
                 else if(half_counter == HALF_PERIOD - 1)
                 begin
                 
                        half_counter <= '0;
                        
                        case(state)
                            
                            START:
                            begin
                                
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                                
                                state <= START_SDA;
                                
                            end
                            
                            START_SDA:
                            begin
                                
                                sda_low <= 1'b1;
                                scl_low <= 1'b0;
                                
                                state <= START_DONE;
                                
                            end
                            
                            START_DONE:
                            begin
                                
                                sda_low <= 1'b1;
                                scl_low <= 1'b1;
                                
                                state <= DONE;
                                
                                
                            end
                            
                            WRITE_BIT:
                            begin
                                
                                scl_low <= 1'b0;
                                state <= WRITE_HIGH;
                                
                            end
                            
                            WRITE_HIGH:
                            begin
                                state <= WRITE_LOW;
                            end
                            
                            WRITE_LOW:
                            begin
                                
                                scl_low <= 1'b1;
                                if(bit_count == 3'd0)
                                begin
                                    sda_low <= 1'b0;
                                    state <= WAIT_ACK;
                                end
                                else
                                begin
                                    bit_count <= bit_count - 1'b1;
                                    
                                    if(tx[bit_count - 1'b1] == 1'b0)
                                        sda_low <= 1'b1;
                                    else
                                        sda_low <= 1'b0;
                                     
                                    state <= WRITE_BIT;
                                end
                            end
                            
                            WAIT_ACK:
                            begin
                                
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                                
                                state <= ACK_HIGH;
                                
                            end
                            
                            ACK_HIGH:
                            begin
                                state<=READ_ACK;
                            end
                            
                            READ_ACK:
                            begin
                                
                                ack <= ~sda_in;
                                
                                state <= ACK_LOW;
                                
                            end
                            
                            ACK_LOW:
                            begin
                                scl_low <= 1'b1;
                                state <= DONE;
                            end
                            
                            READ_BIT:
                            begin
                                
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                                
                                state <= READ_HIGH;
                                
                            end
                            
                            READ_HIGH:
                            begin
                                state <= READ_DATA;
                            end
                            
                            READ_DATA:
                            begin
                            
                                rx[bit_count] <= sda_in;
                                
                                if(bit_count == 3'd0)
                                begin
                                    rx_data <={rx[7:1], sda_in};
                                    
                                state<=READ_LOW;
                                end
                            end
                            
                            READ_LOW:
                            begin
                                scl_low <= 1'b1;
                                if(bit_count == 3'd0)
                                begin
                                    if(read_nack_reg == 1'b0)
                                        sda_low <= 1'b1;
                                    else
                                        sda_low <= 1'b0;
                                    
                                    state <= SEND_ACK;
                                end
                                else
                                begin
                                    bit_count <= bit_count - 1'b1;
                                    state <= READ_BIT;
                                end
                                
                                
                            end
                            
                            SEND_ACK:
                            begin
                                
                                state <= SEND_ACK_HIGH;
                                
                            end
                            
                            SEND_ACK_HIGH:
                            begin
                                scl_low <= 1'b0;

                                state <= SEND_ACK_LOW;
                                
                            end
                            
                            
                            SEND_ACK_LOW:
                            begin
                                scl_low <= 1'b1;
                                sda_low <= 1'b0;
                                state <= DONE;
                            end
                            
                            STOP:
                            begin
                                
                                sda_low <= 1'b1;
                                scl_low <= 1'b0;
                                state <= STOP_HIGH;
                                
                            end
                            
                            STOP_HIGH:
                            begin
                                
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                                
                                state <= STOP_DONE;
                                
                            end
                            
                            STOP_DONE:
                            begin
                                
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                                
                                state <= DONE;
                                
                            end
                            
                            default:
                            begin
                                state <= IDLE;
                                busy <= 1'b0;
                                sda_low <= 1'b0;
                                scl_low <= 1'b0;
                            end
                            
                        endcase
                 end
                 else 
                     half_counter <= half_counter + 1'b1;
            end  
       end
endmodule
