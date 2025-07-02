module top_uart_seven_seg (
    input wire clk,
    input wire uart_rx,
    output wire uart_tx,          // now used
    output wire [7:0] led,
    output wire [7:0] seg,
    output wire [3:0] an
);
    wire [7:0] rx_data;
    wire rx_done;
    reg tx_start = 0;
    wire tx_busy;
    reg [7:0] tx_data;

    // UART Receiver
    uart_rx uart_rx_inst (
        .clk(clk),
        .rx(uart_rx),
        .data_out(rx_data),
        .done(rx_done)
    );

    // UART Transmitter
    uart_tx uart_tx_inst (
        .clk(clk),
        .start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    // Store last received byte
    reg [7:0] last_rx_byte = 0;
    reg [1:0] tx_state = 0;

    always @(posedge clk) begin
        case (tx_state)
            0: begin
                if (rx_done) begin
                    last_rx_byte <= rx_data;
                    tx_data <= rx_data;
                    if (!tx_busy)
                        tx_state <= 1;
                end
                tx_start <= 0;
            end
            1: begin
                tx_start <= 1;  // Pulse start
                tx_state <= 2;
            end
            2: begin
                tx_start <= 0;
                if (!tx_busy)
                    tx_state <= 0;
            end
        endcase
    end

    assign led = last_rx_byte;

    displayMux display_mux_inst (
        .clk(clk),
        .ascii_input(last_rx_byte),
        .an(an),
        .seg(seg)
    );
endmodule