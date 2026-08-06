`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2026 04:07:02 PM
// Design Name: 
// Module Name: i2c_master_v3
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

    
module i2c_master_v3#(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000
                
)(
    input logic clk,
    input logic rst, 
    
    input logic cmd_valid,
    input logic [2:0] cmd,
    
    input logic [7:0] tx_data,
    
    input logic sda_in,
    input logic nack,
    
    output logic sda_out,
    output logic scl_out,
    output logic [7:0] rx_data,
    output logic busy,
    output logic done,
    output logic ack
    
    
    );
    
     
    localparam logic [2:0] CMD_START = 3'b000;
    localparam logic [2:0] CMD_WRITE = 3'b001;
    localparam logic [2:0] CMD_READ  = 3'b010;
    localparam logic [2:0] CMD_STOP  = 3'b011;
    
    localparam integer HALF_PERIOD = CLK_FREQ / (2*I2C_FREQ);
    localparam integer LUNGIME_COUNTER = (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);
    
    logic [LUNGIME_COUNTER - 1:0] half_counter;
    
     
    typedef enum logic [2:0]
    {
        IDLE,
        START,
        WRITE,
        ACK,
        READ,
        STOP,
        DONE

    } state_t;
    
    state_t state; 
    
    
    typedef enum logic [1:0]
    {
        PHASE0,
        PHASE1,
        PHASE2,
        PHASE3

    } phase_t;

    phase_t phase;
    
    
    typedef enum logic
    {
        ACK_READ,
        ACK_WRITE

    } ack_mode_t;

    ack_mode_t ack_mode;
       
       
       
   logic [7:0] tx;
   logic [7:0] rx;
       
   logic [2:0] bit_count;
   logic read_nack_reg;
       
   always @(posedge clk)
       begin
            if(rst)
            begin
                state <= IDLE;
                phase <= PHASE0;
                half_counter <= '0;
                
                tx <= 8'h00;
                rx <= 8'h00;
                rx_data <= 8'h00; 
                
                bit_count <= 3'd7;
                read_nack_reg <= 1'b1;
                ack_mode <= ACK_WRITE;
                
                busy <= 1'b0;
                done <= 1'b0;
                ack <= 1'b0;
                
                sda_out <= 1'b1;
                scl_out <= 1'b1;
            end
            else
            begin
                done <= 1'b0;
                
                if(state == IDLE) 
                begin
                    
                    half_counter <= '0;
                    busy <= 1'b0;
                    
                    phase <= PHASE0;
                    
                    
                    if(cmd_valid)
                    begin
                        busy <= 1'b1;
                        
                        case (cmd)
                        
                            CMD_START:
                            begin
                                
                                state <= START;
                                phase <= PHASE0;
                                
                            end
                            
                            CMD_WRITE:
                            begin
                            
                                tx <= tx_data;
                                bit_count <= 3'd7;
                                ack_mode <= ACK_WRITE;
                                
                                state <= WRITE; 
                                phase <= PHASE0;
                            end
                            
                            CMD_READ:
                            begin
                                
                                rx <= 8'h00;
                                bit_count <= 3'd7;
                                read_nack_reg <= nack;
                                ack_mode <= ACK_READ;
                                
                                state <= READ;
                                phase <= PHASE0;
                                
                            end
                            
                            CMD_STOP:
                            begin
                                
                                state <= STOP;
                                phase <= PHASE0;
                                
                            end
                            
                            default:
                            begin 
                                state <= IDLE;
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
                            case(phase)
                                
                              PHASE0:
                              begin
                                
                                sda_out<= 1'b1;
                                scl_out <= 1'b1;
                                phase <= PHASE1; 
                                                              
                              end
                              
                              PHASE1:
                              begin
                                
                                sda_out<= 1'b0;
                                scl_out <= 1'b1;
                                phase <= PHASE2;
                                
                              end
                            
                              PHASE2:
                              begin
                                
                                sda_out<= 1'b0;
                                scl_out <= 1'b0;
                                phase <= PHASE3;
                                
                              end
                              
                              PHASE3:
                              begin
                                scl_out <= 1'b0;
                                sda_out <= 1'b0;
                                phase <= PHASE0;
                                state <= DONE;
                                
                              end
                             endcase 
                         end     
                            
                            
                         WRITE:
                         begin   
                         
                             case(phase)
                            
                             PHASE0:
                             begin
                                
                                 if(tx[bit_count] == 1'b0)
                                     sda_out <= 1'b0;
                                 else
                                     sda_out <= 1'b1;
                                 
                                 scl_out <= 1'b0;
                                 phase <= PHASE1;
                                
                             end
                            
                             PHASE1:
                             begin
                                
                                scl_out <= 1'b1;
                                
                                phase <= PHASE2;
                                
                             end
                            
                             PHASE2:
                             begin
                                scl_out <= 1'b1;
                                phase <= PHASE3;
                             end
                            
                             PHASE3:
                             begin
                                
                                scl_out <= 1'b0;
                                if(bit_count == 3'd0)
                                begin
                                
                                    phase <= PHASE0;
                                    state <= ACK;
                                    
                                end
                                else
                                begin 
                                    
                                    bit_count <= bit_count - 1'b1;
                                    phase <= PHASE0;
                                    
                                end
                             end
                             
                             endcase
                         end
                         
                         ACK:
                         begin
                             case(phase)
                             
                             PHASE0:
                             begin
                                
                                     scl_out <= 1'b0;
                                     if(ack_mode == ACK_WRITE)
                                        sda_out <= 1'b1;
                                     else
                                     begin
                                        if(read_nack_reg)
                                            sda_out <= 1'b1;
                                        else
                                            sda_out <= 1'b0;
                                     end
                                     
                                     phase <= PHASE1;
                                
                             end
                            
                             PHASE1:
                             begin
                                
                                scl_out <= 1'b1;
                                
                                phase <= PHASE2;
                                
                             end
                            
                             PHASE2:
                             begin
                                
                                if(ack_mode == ACK_WRITE)
                                    ack <= ~sda_in;
                                    
                                phase <= PHASE3;
                                
                             end
                            
                             PHASE3:
                             begin
                                
                                scl_out <= 1'b0;
                                sda_out <= 1'b1;
                                phase <= PHASE0;
                                state <= DONE;
                             end
                             
                             endcase
                         end
                         
                         READ:
                         begin
                         
                            case(phase) 
                                
                                PHASE0: 
                                begin
                                                                        
                                    sda_out <= 1'b1;
                                    scl_out <= 1'b0;
                                    phase <= PHASE1;
                                end
                                
                                PHASE1:
                                begin
                                    scl_out <= 1'b1;
                                    phase <= PHASE2;
                                end
                                
                                PHASE2:
                                begin
                                    scl_out <= 1'b1;
                                    rx[bit_count] <= sda_in;
                                    phase <= PHASE3;
                                end
                                
                                PHASE3:
                                begin
                                    scl_out <= 1'b0;
                                    
                                    if(bit_count == 3'd0)
                                    begin
                                        rx_data <= {rx[7:1], sda_in};
                                        phase <= PHASE0;
                                        state <= ACK;
                                    end
                                    else 
                                    begin
                                        bit_count <= bit_count - 1'b1;
                                        phase <= PHASE0;
                                    end                                
                                end
                             endcase   
                         end                            
                         
                         STOP:
                         begin
                            case(phase)
                                
                              PHASE0:
                              begin
                                
                                sda_out<= 1'b0;
                                scl_out <= 1'b0;
                                phase <= PHASE1;  
                                                              
                              end
                              
                              PHASE1:
                              begin
                                
                                scl_out <= 1'b1;
                                phase <= PHASE2;
                                
                              end
                            
                              PHASE2:
                              begin
                                scl_out <= 1'b1;
                                sda_out<= 1'b1;
                                phase <= PHASE3;
                                
                              end
                              
                              PHASE3:
                              begin
                                
                                phase <= PHASE0;
                                state <= DONE;
                                
                              end
                             endcase 
                         end     
                               
                         default:
                         begin

                            state <= IDLE;

                            phase <= PHASE0;

                            busy <= 1'b0;

                            sda_out <= 1'b1;
                            scl_out <= 1'b1;

                        end   
                     endcase       
                           
                 end
                 else 
                     half_counter <= half_counter + 1'b1;
            end  
       end
endmodule
    
    
    
    
    
    
    
    

