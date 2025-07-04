module apple1_core (
    input  wire clk,       // 100 MHz
    input  wire uart_rx,
    output wire uart_tx,
    output wire [7:0] led,
    output wire [7:0] seg,
    output wire [3:0] an
);

    // UART interface
    wire [7:0] rx_data;
    wire rx_done;
    reg  tx_start = 0;
    wire tx_busy;
    reg  [7:0] tx_data;

    uart_rx uart_rx_i (
        .clk(clk),
        .rx(uart_rx),
        .data_out(rx_data),
        .done(rx_done)
    );

    uart_tx uart_tx_i (
        .clk(clk),
        .start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    // 65C02 CPU wires
    wire [15:0] AD;             // Next-cycle address from CPU
    reg  [15:0] AB = 0;         // Registered address used for writes
    wire [7:0] cpu_data_out;
    wire [7:0] cpu_data_in;
    wire       we;
    wire       sync;
    reg [3:0]  reset_cnt = 4'hF;
    reg        reset;
    wire       rdy = 1'b1;

    // Reset logic
    always @(posedge clk) begin
        if (reset_cnt != 0)
            reset_cnt <= reset_cnt - 1;
        reset <= (reset_cnt != 0);
    end

    // Register AB on RDY
    always @(posedge clk) begin
        if (rdy)
            AB <= AD;
    end

    cpu cpu65c02 (
        .clk   (clk),
        .RST   (reset),
        .AD    (AD),
        .sync  (sync),
        .DI    (cpu_data_in),
        .DO    (cpu_data_out),
        .WE    (we),
        .IRQ   (1'b0),
        .NMI   (1'b0),
        .RDY   (rdy),
        .debug (1'b0)
    );

    // Main memory (64K)
    reg [7:0] ram [0:65535];
    initial $readmemh("apple1_rom.mem", ram);

    // UART MMIO
    reg [7:0] uart_rx_reg;
    reg       uart_rx_ready;
    reg       uart_tx_latch;
    reg       uart_tx_latch_d;
    reg       uart_tx_latch_d2;

    // UART receive
    always @(posedge clk) begin
        if (rx_done) begin
            uart_rx_reg <= rx_data;
            uart_rx_ready <= 1;
        end else if (AD == 16'hFF00 && !we && rdy) begin
            uart_rx_ready <= 0;
        end
    end

    // UART transmit logic
    always @(posedge clk) begin
        if (AD == 16'hFF01 && we && rdy) begin
            uart_tx_latch <= 1;
            tx_data <= cpu_data_out;
        end else begin
            uart_tx_latch <= 0;
        end

        uart_tx_latch_d <= uart_tx_latch;
        uart_tx_latch_d2 <= uart_tx_latch_d;
    end

    wire uart_tx_start_pulse = (uart_tx_latch && !uart_tx_latch_d);

    always @(posedge clk) begin
        if (uart_tx_start_pulse && !tx_busy)
            tx_start <= 1;
        else
            tx_start <= 0;
    end

    // Memory read (synchronous behavior)
    reg [7:0] mmio_data;
    always @(posedge clk) begin
        if (rdy) begin
            if (AD == 16'hFF00)
                mmio_data <= uart_rx_ready ? uart_rx_reg : 8'h00;
            else if (AD == 16'hFF01)
                mmio_data <= {7'b0, tx_busy};
            else
                mmio_data <= ram[AD];
        end
    end

    assign cpu_data_in = mmio_data;

    // Memory write (using registered AB)
    always @(posedge clk) begin
        if (we && rdy && AB != 16'hFF00 && AB != 16'hFF01) begin
            ram[AB] <= cpu_data_out;
        end
    end

    // Visual debug
    displayMux dvm (
        .clk(clk),
        .ascii_input(uart_rx_reg),
        .an(an),
        .seg(seg)
    );

    assign led = AB[7:0];
endmodule