`timescale 1ns / 1ps

module uart_rx (
    input wire clk,            // 100 MHz system clock
    input wire rx,             // Serial RX input
    output reg [7:0] data_out, // Received byte
    output reg done            // High for 1 clk after byte received
);

    // Parameters for 115200 baud rate with 100 MHz clock
    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter SAMPLE_TICKS = CLK_FREQ / (BAUD_RATE * 16); // oversample by 16

    // FSM States
    parameter IDLE  = 3'b000;
    parameter START = 3'b001;
    parameter DATA  = 3'b010;
    parameter STOP  = 3'b011;
    parameter DONE  = 3'b100;

    reg [2:0] state = IDLE;

    reg [13:0] clk_count = 0;  // Up to ~6250 ticks
    reg [3:0] sample_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_shift = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                clk_count <= 0;
                sample_count <= 0;
                bit_index <= 0;
                if (rx == 0) begin  // start bit detected
                    state <= START;
                end
            end

            START: begin
                if (clk_count == SAMPLE_TICKS - 1) begin
                    clk_count <= 0;
                    sample_count <= sample_count + 1;
                    if (sample_count == 7) begin  // midpoint sample
                        if (rx == 0) begin
                            state <= DATA;
                            sample_count <= 0;
                            bit_index <= 0;
                        end else begin
                            state <= IDLE;  // false start
                        end
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                if (clk_count == SAMPLE_TICKS - 1) begin
                    clk_count <= 0;
                    sample_count <= sample_count + 1;
                    if (sample_count == 15) begin
                        rx_shift[bit_index] <= rx;
                        bit_index <= bit_index + 1;
                        sample_count <= 0;
                        if (bit_index == 7) begin
                            state <= STOP;
                        end
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            STOP: begin
                if (clk_count == SAMPLE_TICKS - 1) begin
                    clk_count <= 0;
                    sample_count <= sample_count + 1;
                    if (sample_count == 15) begin
                        data_out <= rx_shift;
                        done <= 1;
                        state <= DONE;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DONE: begin
                done <= 0;      // pulse for 1 clock
                state <= IDLE; // restart FSM
            end

            default: state <= IDLE;
        endcase
    end

endmodule