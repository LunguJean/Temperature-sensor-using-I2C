`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2026 07:19:04 PM
// Design Name: 
// Module Name: tb_master_slave
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


module tb_master_slave();

    localparam integer CLK_FREQ = 100_000_000;
    localparam integer I2C_FREQ = 100_000;
    
    typedef enum logic [2:0] 
    {
        CMD_START = 3'd0, 
        CMD_WRITE = 3'd1, 
        CMD_READ = 3'd2, 
        CMD_STOP = 3'd3
    
    } i2c_cmd_t;
    
    
    i2c_cmd_t cmd;

    logic clk;
    logic rst;
    logic nack;
    logic cmd_valid;
    logic [7:0] master_tx;

    logic scl;

    logic master_sda_o;
    logic slave_sda_o;
    logic bus;

    logic [7:0] master_rx;
    logic ack;
    logic busy;
    logic done;
    logic [7:0] slave_rx;
    logic [7:0] slave_tx;
    
    assign bus = master_sda_o & slave_sda_o;
    
    initial begin
        
        clk = 1'b0;
        
        forever #5 clk = ~clk;
        
    end    
    
    task I2C_SEND_CMD;
        
        input i2c_cmd_t command;
        input [7:0] data;
        
        begin
            
            wait(busy == 1'b0);
            
            @(negedge clk);
            
            cmd = command;
            master_tx = data;
            cmd_valid = 1'b1;
            
            @(negedge clk);
            
            cmd_valid = 1'b0;
            
            wait(busy == 1'b1);
            @(posedge done);
            @(negedge clk);
        end
    endtask
    
    initial begin
    
        rst = 1'b1;
        cmd_valid = 1'b0;
        
        cmd = CMD_START;
        
        master_tx = 8'h00;
        nack = 1'b1;
        
        slave_tx = 8'hA2;
        
        repeat(5)
            @(posedge clk);
        
        
        //reset
        @(negedge clk);
        
        rst = 1'b0;
        
        repeat(3)
             @(posedge clk);
             
        //start
        
        I2C_SEND_CMD(
            CMD_START,
            8'h00
            );
        
        //write byt 1
         I2C_SEND_CMD(
            CMD_WRITE,
            8'hB2
            );
         
         //write byt 2
         I2C_SEND_CMD(
            CMD_WRITE,
            8'h24
            );
        
         //repeated start
         I2C_SEND_CMD(
            CMD_START,
            8'h00
            );
          
         //write byt 3
         I2C_SEND_CMD(
            CMD_WRITE,
            8'h12
            );
        
        nack = 1'b1;
         //read
         I2C_SEND_CMD(
            CMD_READ,
            8'h00
            );
        //stop
         I2C_SEND_CMD(
            CMD_STOP,
            8'h00
            );
         
          repeat(20)
               @(posedge clk);
          
          $finish;
             
    end
    
    i2c_master_v3 #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) dut_master (

        .clk(clk),
        .rst(rst),

        .cmd_valid(cmd_valid),
        .cmd(cmd),

        .tx_data(master_tx),

        .sda_in(bus),
        .nack(nack),
        
        .sda_out(master_sda_o),
        .scl_out(scl),

        .rx_data(master_rx),

        .ack(ack),
        .busy(busy),
        .done(done)

    );
    
    i2c_dummy_slave dut_slave (

        .clk(clk),
        .rst(rst),

        .scl_i(scl),
        .sda_i(bus),

        .sda_out_o(slave_sda_o),

        .rx_o(slave_rx),

        .tx_i(slave_tx)

    );
endmodule
