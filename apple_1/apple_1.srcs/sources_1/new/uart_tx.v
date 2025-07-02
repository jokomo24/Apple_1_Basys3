`timescale 1ns / 1ps

module uart_tx (
    input wire clk,              // 100 MHz clock
    input wire start,            // Trigger transmission
    input wire [7:0] data_in,    // Byte to transmit
    output reg tx,               // Serial output
    output reg busy              // High when transmitting
);

    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [13:0] clk_count = 0;
    reg [3:0] bit_index = 0;
    reg [9:0] tx_shift = 10'b1111111111;  // Start + data + stop
    reg tx_active = 0;

    always @(posedge clk) begin
        if (!tx_active) begin
            if (start) begin
                tx_shift <= {1'b1, data_in, 1'b0};  // stop, data, start
                tx_active <= 1;
                clk_count <= 0;
                bit_index <= 0;
                busy <= 1;
            end
        end else begin
            if (clk_count == CLKS_PER_BIT - 1) begin
                clk_count <= 0;
                tx <= tx_shift[bit_index];
                bit_index <= bit_index + 1;
                if (bit_index == 9) begin
                    tx_active <= 0;
                    busy <= 0;
                end
            end else begin
                clk_count <= clk_count + 1;
            end
        end
    end

    initial tx = 1; // Idle state is high
endmodule