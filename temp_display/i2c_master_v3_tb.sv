`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/03/2026 06:48:01 PM
// Design Name: 
// Module Name: i2c_master_v3_tb
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


`timescale 1ns / 1ps

module i2c_master_v3_tb(

);

    localparam integer CLK_FREQ = 100_000_000;
    localparam integer I2C_FREQ = 10_000_000;

    typedef enum logic [2:0] {
        CMD_START = 3'd0,
        CMD_WRITE = 3'd1,
        CMD_READ  = 3'd2,
        CMD_STOP  = 3'd3
    } i2c_cmd_t;

    logic clk;
    logic rst;

    logic cmd_valid;
    i2c_cmd_t cmd;
    logic [7:0] tx_data;
    logic nack;

    logic sda_in;
    logic sda_out;
    logic slave_out;

    logic scl_out;

    logic [7:0] rx_data;
    logic busy;
    logic done;
    logic ack;

    always_comb begin
        sda_in = sda_out & slave_out;
    end

    initial 
    begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    task automatic send_cmd(
        input i2c_cmd_t command,
        input logic [7:0] data
    );
    begin
        wait(busy == 1'b0);

        @(negedge clk);

        cmd = command;
        tx_data = data;
        cmd_valid = 1'b1;

        @(negedge clk);

        cmd_valid = 1'b0;

        wait(busy == 1'b1);
    end
    endtask



    task automatic simple_cmd(
        input i2c_cmd_t command
    );
    begin
        send_cmd(command, 8'h00);

        @(posedge done);

        @(negedge clk);
    end
    endtask


    task automatic write_byte(
        input logic [7:0] data
    );

        integer i;

    begin
        send_cmd(CMD_WRITE, data);

        for(i = 7; i >= 0; i = i - 1) begin
            @(posedge scl_out);
            @(negedge scl_out);
        end

        slave_out = 1'b0;

        @(posedge scl_out);
        @(negedge scl_out);

        slave_out = 1'b1;

        @(posedge done);
        @(negedge clk);
    end
    endtask


    task automatic read_byte(
        input logic [7:0] data
    );

        integer i;

    begin
        send_cmd(CMD_READ, 8'h00);

        wait(scl_out == 1'b0);
        slave_out = data[7];

        for(i = 7; i >= 0; i = i - 1) 
        begin
            @(posedge scl_out);

            @(negedge scl_out);

            if(i > 0)
                slave_out = data[i-1];
            else
                slave_out = 1'b1;
        end
        slave_out = 1'b1;

        @(posedge done);
        @(negedge clk);
    end
    endtask



    initial begin

        rst = 1'b1;
        cmd_valid = 1'b0;
        cmd = CMD_START;
        tx_data = 8'h00;
        nack = 1'b1;
        slave_out = 1'b1;

        repeat(5)
            @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        repeat(3)
            @(posedge clk);

        simple_cmd(CMD_START);

        write_byte(8'h3A);

        simple_cmd(CMD_START);
        
        nack = 1'b1;
        read_byte(8'h4B);

        simple_cmd(CMD_STOP);

        repeat(20)
            @(posedge clk);

        $finish;
    end

    i2c_master_v3 #(
        .CLK_FREQ(CLK_FREQ),
        .I2C_FREQ(I2C_FREQ)
    ) dut (
        .clk(clk),
        .rst(rst),

        .cmd_valid(cmd_valid),
        .cmd(cmd),

        .tx_data(tx_data),

        .sda_in(sda_in),
        .nack(nack),

        .sda_out(sda_out),
        .scl_out(scl_out),

        .rx_data(rx_data),
        .busy(busy),
        .done(done),
        .ack(ack)
    );

endmodule