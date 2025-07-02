`timescale 1ns / 1ps

module displayMux (
    input wire clk,                    // 100 MHz clock
    input wire [7:0] ascii_input,      // ASCII input byte
    output reg [3:0] an,               // Anode control (active low)
    output reg [7:0] seg               // Segment control
);

    // Counter for multiplexing display at a reasonable refresh rate
    reg [17:0] counter = 0;
    always @(posedge clk)
        counter <= counter + 1;

    // Select digit index
    wire [1:0] digit = counter[17:16]; // Slow bit switching for digit refresh

    // ASCII input split into high and low nibble
    wire [3:0] nibble0 = ascii_input[3:0];
    wire [3:0] nibble1 = ascii_input[7:4];

    // Hex to 7-segment decoder
    function [7:0] hex_to_7seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_7seg = 8'b11000000;
                4'h1: hex_to_7seg = 8'b11111001;
                4'h2: hex_to_7seg = 8'b10100100;
                4'h3: hex_to_7seg = 8'b10110000;
                4'h4: hex_to_7seg = 8'b10011001;
                4'h5: hex_to_7seg = 8'b10010010;
                4'h6: hex_to_7seg = 8'b10000010;
                4'h7: hex_to_7seg = 8'b11111000;
                4'h8: hex_to_7seg = 8'b10000000;
                4'h9: hex_to_7seg = 8'b10010000;
                4'hA: hex_to_7seg = 8'b10001000;
                4'hB: hex_to_7seg = 8'b10000011;
                4'hC: hex_to_7seg = 8'b11000110;
                4'hD: hex_to_7seg = 8'b10100001;
                4'hE: hex_to_7seg = 8'b10000110;
                4'hF: hex_to_7seg = 8'b10001110;
                default: hex_to_7seg = 8'b11111111; // All off
            endcase
        end
    endfunction

    always @(*) begin
        // Default all anodes off and segments blank
        an = 4'b1111;
        seg = 8'b11111111;

        case (digit)
            2'b00: begin
                an = 4'b1110;           // Activate digit 0 (rightmost)
                seg = hex_to_7seg(nibble0);
            end
            2'b01: begin
                an = 4'b1101;           // Activate digit 1
                seg = hex_to_7seg(nibble1);
            end
            default: begin
                an = 4'b1111;           // Other digits off
                seg = 8'b11111111;      // Blank
            end
        endcase
    end

endmodule