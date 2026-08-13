`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2026 05:11:55 PM
// Design Name: 
// Module Name: i2c_dummy_slave
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


module i2c_dummy_slave(
    input logic clk,
    input logic rst, 
    
    input logic scl_i,
    input logic sda_i,
    output logic sda_out_o,
    
    output logic [7:0] rx_o,
    input logic [7:0] tx_i
    );
    
    typedef enum logic [2:0] { 
        START,
        RX,
        ACK,
        ACK_END,
        REPEATED_START,
        TX,
        NACK,
        STOP
    
    } state_t;
    
    state_t state;
    
    logic scl_old,sda_old;
    
    logic [2:0] bit_index;
    
    logic [1:0] byte_count;
    
    
    always @(posedge clk)
    begin
        
        if(rst)
        begin
            state <= START;
            scl_old <= 1'b1;
            sda_old <= 1'b1;
            
            sda_out_o <= 1'b1;

            rx_o <= 8'h00; 
            bit_index <= 3'd7;
            byte_count <= 2'd0;
                        
        end
        else
        begin
            
            scl_old <= scl_i;
            sda_old <= sda_i;
            
            case(state)
                
                START:
                begin
                
                    sda_out_o <= 1'b1;
                    
                    if(sda_old && !sda_i && scl_i)
                    begin
                        rx_o <= 8'h00;
                        bit_index <= 3'd7;
                        byte_count <= 2'd0;
                        state <= RX;
                    end
                    
                end
                
                RX:
                begin  
                    if(scl_i && !scl_old)
                    begin
                        
                        rx_o[bit_index] <= sda_i;
                        
                        if(bit_index == 3'd0)
                        begin
                            
                            bit_index <= 3'd7;
                            byte_count <= byte_count + 1'b1;
                            
                            state <= ACK;
                            
                        end
                        else
                        begin
                            bit_index <= bit_index - 1'b1;
                        end
                        
                    end
                end
                
                ACK:
                begin
                    
                    if(!scl_i && scl_old)
                    begin
                        sda_out_o <= 1'b0;
                       
                    end
                    
                    if(scl_i && !scl_old)
                    begin
                        state <= ACK_END;
                    end
                    
                    
                end
                
                ACK_END:
                begin
                    
                    if(!scl_i && scl_old)
                    begin
                        
                        if(byte_count == 2'd1)
                        begin
                            sda_out_o <= 1'b1;
                            rx_o <= 8'h00;
                            bit_index <= 3'd7;
                            state <= RX;
                        end
                        
                        else if(byte_count == 2'd2)
                        begin
                            sda_out_o <= 1'b1;
                            state <= REPEATED_START;
                        end
                        
                        else
                        begin
                            bit_index <= 3'd7;
                            sda_out_o <= tx_i[7];
                            state <= TX;
                        end
                        
                    end
                    
                end
                
                REPEATED_START:
                begin  
                    
                    sda_out_o <= 1;
                    if(sda_old && !sda_i && scl_i)
                    begin
                        
                        rx_o <= 8'h00; 
                        bit_index <= 3'd7;
                        state <= RX;
                        
                    end
                    
                end
                
                TX:
                begin
                    
                   
                    if(!scl_i && scl_old)
                    begin
                        sda_out_o <= tx_i[bit_index];
                    end

                    if(scl_i && !scl_old)
                    begin

                        if(bit_index == 3'd0)
                        begin
                            state <= NACK;
                        end
                        else
                        begin
                            bit_index <= bit_index - 1'b1;
                        end

                    end

                    
                end
                
                NACK:
                begin  
                    
                    if(!scl_i && scl_old)
                        sda_out_o <= 1'b1;
                    if(scl_i && !scl_old)
                    begin
                        if(sda_i == 1'b1)
                            state <= STOP;
                    end
                    
                end
                
                STOP:
                begin
                    
                    sda_out_o <= 1'b1;
                    if(!sda_old && sda_i && scl_i)
                        state <= START;
                    
                end
                
                default: 
                begin
                    state <= START;
                    sda_out_o <= 1'b1;
                end
                
            endcase
        end
    
    end
    
endmodule
