`timescale 1ns / 1ps

module apple1_core (
    input wire clk,            // 100 MHz clock
    input wire uart_rx,        // UART RX input,
    input reset,  
    output wire uart_tx,       // UART TX output
    output wire [7:0] led,     // LEDs
    output wire [7:0] seg,     // 7-segment segments
    output wire [3:0] an
);
    // UART logic (reuse from top_uart_seven_seg)
    wire [7:0] rx_data;
    wire rx_done;
    reg tx_start = 0;
    wire tx_busy;
    reg [7:0] tx_data;

    uart_rx uart_rx_inst (
        .clk(clk),
        .rx(uart_rx),
        .data_out(rx_data),
        .done(rx_done)
    );

    uart_tx uart_tx_inst (
        .clk(clk),
        .start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    // Clock divider for CPU (1 MHz from 100 MHz input)
    reg [6:0] clkdiv = 0;
    reg cpu_clk = 0;
    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
        if (clkdiv == 49) begin // 100 MHz / 50 / 2 = 1 MHz (toggle every 50 cycles)
            clkdiv <= 0;
            cpu_clk <= ~cpu_clk;
        end
    end

    // 65C02 CPU signals
    wire [15:0] cpu_addr;
    wire [7:0] cpu_data_in;
    wire [7:0] cpu_data_out;
    wire cpu_we;
    wire cpu_sync;
    wire cpu_irq = 1'b0;
    wire cpu_nmi = 1'b0;
    wire cpu_rdy = 1'b1;
    wire cpu_debug = 1'b1; // Enable CPU debug output

    // --- Power-on Reset Pulse ---
    // Uncomment this block to enable a power-on reset pulse for the CPU
    reg [7:0] reset_counter = 0;
    reg cpu_rst = 1'b0;
    always @(posedge clk) begin
        if (reset_counter < 100) begin
            reset_counter <= reset_counter + 1;
            cpu_rst <= 1'b0; // Hold CPU in reset (active low)
        end else begin
            cpu_rst <= ~reset; // Invert external reset (active-low to active-low)
        end
    end
    // --- End Power-on Reset Pulse ---


    cpu cpu_inst (
        .clk(cpu_clk), // Use divided clock
        .RST(cpu_rst),
        .AD(cpu_addr),
        .sync(cpu_sync),
        .DI(cpu_data_in),
        .DO(cpu_data_out),
        .WE(cpu_we),
        .IRQ(cpu_irq),
        .NMI(cpu_nmi),
        .RDY(cpu_rdy),
        .debug(cpu_debug)
    );

    // Apple 1 memory map
    // $0000-$0FFF: 4KB RAM
    // $D000: UART RX (read)
    // $D001: UART TX (write)
    // $E000-$FFFF: 8KB ROM
    reg [7:0] ram [0:4095];
    reg [7:0] rom [0:8191];
    initial $readmemh("apple1_rom.mem", rom, 0); // Use Apple 1 monitor or test program

    // Address decoding
    wire ram_sel  = (cpu_addr[15:12] == 4'h0);           // $0000-$0FFF
    wire uart_sel = (cpu_addr[15:8]  == 8'hD0);          // $D000-$D0FF
    wire rom_sel  = (cpu_addr[15:13] == 3'b111);         // $E000-$FFFF
    wire uart_rx_sel = uart_sel && (cpu_addr[0] == 1'b0); // $D000
    wire uart_tx_sel = uart_sel && (cpu_addr[0] == 1'b1); // $D001

    // UART RX data register
    reg [7:0] uart_rx_data = 8'h00;

    // CPU data bus input mux
    assign cpu_data_in = ram_sel      ? ram[cpu_addr[11:0]] :
                        rom_sel      ? rom[cpu_addr[12:0]] :
                        uart_rx_sel  ? uart_rx_data :
                        uart_tx_sel  ? {7'b0, tx_busy} :
                        8'hFF;

    // UART RX data register
    always @(posedge clk) begin
        if (rx_done)
            uart_rx_data <= rx_data;
    end

    // RAM write
    always @(posedge clk) begin
        if (cpu_we && ram_sel)
            ram[cpu_addr[11:0]] <= cpu_data_out;
    end

    // UART TX trigger from CPU write
    always @(posedge clk) begin
        if (cpu_we && uart_tx_sel && !tx_busy) begin
            tx_data <= cpu_data_out;
            tx_start <= 1;
        end else begin
            tx_start <= 0;
        end
    end

    // LED and 7-segment display: show debug information
    reg [7:0] debug_led = 8'h00;
    reg [7:0] last_rx_byte = 8'h00;
    reg [7:0] last_tx_byte = 8'h00;
    reg led_toggle = 0;
    
    // Heartbeat counter (100 MHz / 100,000,000 = 1 Hz)
    reg [26:0] heartbeat_counter = 0;
    reg heartbeat_led = 0;
    always @(posedge clk) begin
        heartbeat_counter <= heartbeat_counter + 1;
        if (heartbeat_counter == 27'd100_000_000) begin
            heartbeat_counter <= 0;
            heartbeat_led <= ~heartbeat_led;
        end
    end
    
    always @(posedge clk) begin
        if (rx_done) begin
            last_rx_byte <= rx_data;
            debug_led <= rx_data; // Show received byte immediately
        end
        if (cpu_we && uart_tx_sel) begin
            last_tx_byte <= cpu_data_out;
            led_toggle <= ~led_toggle; // Toggle to show CPU activity
            debug_led <= cpu_data_out; // Show transmitted byte
        end
    end

    // assign led = last_tx_byte;
    assign led = {heartbeat_led, debug_led[6:0]}; // Show heartbeat on LED7, debug on LED6-0
    displayMux display_mux_inst (
        .clk(clk),
        .ascii_input(last_tx_byte),
        .an(an),
        .seg(seg)
    );

endmodule 