`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2026 07:04:43 PM
// Design Name: 
// Module Name: temp_controller
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


module temp_controller#(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer I2C_FREQ = 100_000,
    parameter integer FIRST_READ_DELAY = 1_000_000,
    parameter integer READ_INTERVAL = 24_000_000

)(
        input logic clk,
        input logic rst,
        
        input logic sda_in,
        output logic sda_out,
        output logic scl_out,
        
        output logic [15:0] temperature_raw,
        output logic data_valid,
        output logic ack_error
    );
    
    localparam logic [2:0] CMD_START = 3'b000;
    localparam logic [2:0] CMD_WRITE = 3'b001;
    localparam logic [2:0] CMD_READ  = 3'b010;
    localparam logic [2:0] CMD_STOP  = 3'b011;
    
    
    localparam logic [7:0] SENSOR_ADDRESS_WRITE = 8'h96;
    localparam logic [7:0] SENSOR_ADDRESS_READ = 8'h97; 
    
    localparam logic [7:0] TEMPERATURE_REGISTER = 8'h00;
    
    typedef enum logic [4:0] {
        IDLE,

        SEND_START_WRITE,
        WAIT_START_WRITE,

        SEND_ADDRESS_WRITE,
        WAIT_ADDRESS_WRITE,

        SEND_REGISTER_ADDRESS,
        WAIT_REGISTER_ADDRESS,

        SEND_REPEATED_START,
        WAIT_REPEATED_START,

        SEND_ADDRESS_READ,
        WAIT_ADDRESS_READ,

        SEND_READ_MSB,
        WAIT_READ_MSB,

        SEND_READ_LSB,
        WAIT_READ_LSB,

        SEND_STOP,
        WAIT_STOP,

        SAVE_RESULT,
        WAIT_NEXT_READ

    } state_t;
    
    state_t state;
    
    logic cmd_valid;
    logic [2:0] cmd;
    logic [7:0] tx_data;
    logic nack;

    logic [7:0] i2c_rx_data;
    logic i2c_busy;
    logic i2c_done;
    logic i2c_ack;
    
    logic [7:0] msb;
    logic [7:0] lsb;
    
    logic [31:0] wait_counter;
    logic first_read;
    
    i2c_master_v3 #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) I2C_MASTER (
        .clk(clk),
        .rst(rst),

        .cmd_valid(cmd_valid),
        .cmd(cmd),
        .tx_data(tx_data),

        .sda_in(sda_in),
        .nack(nack),

        .sda_out(sda_out),
        .scl_out(scl_out),

        .rx_data(i2c_rx_data),
        .busy(i2c_busy),
        .done(i2c_done),
        .ack(i2c_ack)
    );
    
    always @(*)
    begin
        cmd_valid = 1'b0;
        cmd = CMD_START;
        tx_data = 8'h00;
        nack = 1'b1;
        
        case (state)

            SEND_START_WRITE: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_START;
            end

            SEND_ADDRESS_WRITE: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_WRITE;
                tx_data = SENSOR_ADDRESS_WRITE;
            end

            SEND_REGISTER_ADDRESS: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_WRITE;
                tx_data = TEMPERATURE_REGISTER;
            end

            SEND_REPEATED_START: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_START;
            end

            SEND_ADDRESS_READ: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_WRITE;
                tx_data = SENSOR_ADDRESS_READ;
            end

            SEND_READ_MSB: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_READ;
                nack = 1'b0;
            end

            SEND_READ_LSB: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_READ;
                nack = 1'b1;
            end

            SEND_STOP: 
            begin
                cmd_valid = 1'b1;
                cmd = CMD_STOP;
            end

            default: begin
                cmd_valid = 1'b0;
            end

        endcase    
    end
    
    always @(posedge clk)
    begin
        if(rst)
        begin
            state <= IDLE;
            
            msb <= 8'h00;
            lsb <= 8'h00;
            temperature_raw <= 16'h0000;
        
            data_valid <= 1'b0;
            ack_error <= 1'b0;
            
            wait_counter <= 32'd0;
            first_read <= 1'b1;
       
        end
        else
        begin
            
            data_valid <= 1'b0;
            
            case(state)
                
                IDLE:
                begin
                    ack_error <= 1'b0;
                    
                    if(first_read)
                    begin
                        if(wait_counter == FIRST_READ_DELAY - 1)
                        begin
                            wait_counter <= 32'd0;
                            first_read <= 1'b0;
                            
                            state <= SEND_START_WRITE;
                        end
                        else
                        begin
                            wait_counter <= wait_counter + 1'b1;
                        end
                    end
                    else
                    begin
                        if(wait_counter == READ_INTERVAL - 1)
                        begin
                            wait_counter <= 32'd0;
                            state <= SEND_START_WRITE;
                        end
                        else
                        begin
                            wait_counter <= wait_counter + 1'b1;
                        end
                    end
                end
                
                
                
                
                SEND_START_WRITE:
                begin
                    if(!i2c_busy)
                        state <= WAIT_START_WRITE;
                end
                
                WAIT_START_WRITE:
                begin
                    if(i2c_done)
                        state <= SEND_ADDRESS_WRITE;
                end
                
                
                
                
                SEND_ADDRESS_WRITE:
                begin
                    if(!i2c_busy)
                        state <= WAIT_ADDRESS_WRITE;
                end
                
                WAIT_ADDRESS_WRITE:
                begin
                    if(i2c_done)
                    begin
                        if(i2c_ack)
                            state <= SEND_REGISTER_ADDRESS;
                        else
                        begin
                            ack_error <= 1'b1;
                            state <= SEND_STOP;
                        end
                    end
                end
                
                
                
                
                
                SEND_REGISTER_ADDRESS:
                begin
                    if(!i2c_busy)
                        state <= WAIT_REGISTER_ADDRESS;
                end
                
                WAIT_REGISTER_ADDRESS:
                begin
                    if(i2c_done)
                    begin
                        if(i2c_ack)
                            state <= SEND_REPEATED_START;
                        else
                        begin
                            ack_error <= 1'b1;
                            state <= SEND_STOP;
                        end
                    end
                end
                
                
                
                
                SEND_REPEATED_START:
                begin
                    if(!i2c_busy)
                        state <= WAIT_REPEATED_START;
                end
                
                WAIT_REPEATED_START:
                begin
                    if(i2c_done)
                        state <= SEND_ADDRESS_READ;
                end
                
                
                
                
                SEND_ADDRESS_READ:
                begin
                    if(!i2c_busy)
                        state <= WAIT_ADDRESS_READ;
                end
                
                WAIT_ADDRESS_READ:
                begin
                    if(i2c_done)
                    begin
                        if(i2c_ack)
                            state <= SEND_READ_MSB;
                        else
                        begin
                            ack_error <= 1'b1;
                            state <= SEND_STOP;
                        end
                    end
                end
                
                
                //MSB
                SEND_READ_MSB:
                begin
                    if(!i2c_busy)
                        state <= WAIT_READ_MSB;
                end
                
                WAIT_READ_MSB:
                begin
                    if(i2c_done)
                    begin
                        msb <= i2c_rx_data;
                        state <= SEND_READ_LSB;
                    end
                end
                
                
                //LSB
                SEND_READ_LSB:
                begin
                    if(!i2c_busy)
                        state <= WAIT_READ_LSB;
                end
                
                WAIT_READ_LSB:
                begin
                    if(i2c_done)
                    begin
                        lsb <= i2c_rx_data;
                        state <= SEND_STOP;
                    end
                end
                
                
                //STOP
                SEND_STOP:
                begin
                    if(!i2c_busy)
                        state <= WAIT_STOP;
                end
                
                WAIT_STOP:
                begin
                    if(i2c_done)
                    begin
                        if(ack_error)
                            state <= WAIT_NEXT_READ;
                        else
                            state <= SAVE_RESULT;
                    end
                end
                
                //SAVE
                SAVE_RESULT:
                begin
                    temperature_raw <= {msb,lsb};
                    data_valid <= 1'b1;
                    state <= WAIT_NEXT_READ;
                end
                
                WAIT_NEXT_READ:
                begin
                    wait_counter <= 32'd0;
                    state <= IDLE;
                end
                
                default: 
                begin
                    state <= IDLE;
                    wait_counter <= 32'd0;
                end 
            endcase
        end
    end
   
endmodule
