`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2026 03:32:13 AM
// Design Name: 
// Module Name: i2c_testbench
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


module i2c_testbench(

    );


    localparam integer CLK_FREQ = 100_000_000;
    localparam integer I2C_FREQ = 10_000_000;

    localparam logic [2:0] CMD_START = 3'b000;
    localparam logic [2:0] CMD_WRITE = 3'b001;
    localparam logic [2:0] CMD_READ  = 3'b010;
    localparam logic [2:0] CMD_STOP  = 3'b011;

    logic clk;
    logic rst;

    logic cmd_valid;
    logic [2:0] cmd;
    logic [7:0] tx_data;
    logic nack;

    logic [7:0] rx_data;
    logic busy;
    logic done;
    logic ack;

    wire i2c_scl;
    wire i2c_sda;

    logic slave_sda_low;

    assign i2c_sda = slave_sda_low ? 1'b0 : 1'bz;

    pullup(i2c_sda);
    pullup(i2c_scl);

    i2c_master #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .cmd_valid (cmd_valid),
        .cmd(cmd),
        .tx_data(tx_data),
        .nack(nack),
        .rx_data(rx_data),
        .busy(busy),
        .done(done),
        .ack(ack),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        cmd_valid = 1'b0;
        cmd = CMD_START;
        tx_data = 8'h00;
        nack = 1'b1;
        slave_sda_low = 1'b0;

        repeat (5)
            @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        repeat (3)
            @(posedge clk);

        // START

        @(negedge clk);
        cmd = CMD_START;
        cmd_valid = 1'b1;

        @(negedge clk);
        cmd_valid = 1'b0;

        @(posedge done);

        repeat (3)
            @(posedge clk);

        // WRITE 8'hA5

        tx_data = 8'hA5;

        @(negedge clk);
        cmd = CMD_WRITE;
        cmd_valid = 1'b1;

        @(negedge clk);
        cmd_valid = 1'b0;

       
        repeat (8)
            @(posedge i2c_scl);

        
        @(negedge i2c_scl);
        slave_sda_low = 1'b1;

        
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        slave_sda_low = 1'b0;

        @(posedge done);

        repeat (3)
            @(posedge clk);

        // READ 8'h3C

        nack = 1'b1;

        @(negedge clk);
        cmd = CMD_READ;
        cmd_valid = 1'b1;

        @(negedge clk);
        cmd_valid = 1'b0;

        
        wait(i2c_scl == 1'b0);
        slave_sda_low = 1'b1;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b1;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

      
        slave_sda_low = 1'b0;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b0;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b0;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b0;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b1;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b1;
        @(posedge i2c_scl);
        @(negedge i2c_scl);

        
        slave_sda_low = 1'b0;

        @(posedge done);

        repeat (3)
            @(posedge clk);

        // STOP

        @(negedge clk);
        cmd = CMD_STOP;
        cmd_valid = 1'b1;

        @(negedge clk);
        cmd_valid = 1'b0;

        @(posedge done);

        repeat (10)
            @(posedge clk);

        $finish;
    end

endmodule
    
    

