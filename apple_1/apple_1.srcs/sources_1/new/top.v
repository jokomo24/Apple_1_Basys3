// Top-level module for Basys3 with 65C02 core, RAM, ROM, LEDs, 7-seg, switches
module top(
    input clk,
    input reset,           // Connect to Basys3 btnC (see .xdc)
    input [7:0] sw,
    output reg [7:0] led,
    output reg [7:0] seg,
    output reg [3:0] an
);
    // Clock divider for slow CPU clock
    reg [15:0] clkdiv = 0;
    reg cpu_clk = 0;
    always @(posedge clk) begin
        clkdiv <= clkdiv + 1;
        cpu_clk <= clkdiv[15];
    end

    // Invert reset for active-low CPU reset
    wire reset_n = ~reset;

    // 65C02 signals
    wire [15:0] A;
    wire [7:0] DI;
    wire [7:0] DO;
    wire WE;
    wire IRQ = 1'b0;
    wire NMI = 1'b0;

    // RAM (2KB at 0x0000-0x07FF)
    reg [7:0] ram[0:2047];
    wire ram_sel = (A[15:11] == 5'b00000); // 0x0000-0x07FF

    // ROM (2KB at 0xF800-0xFFFF)
    reg [7:0] rom[0:2047];
    wire rom_sel = (A[15:11] == 5'b11111); // 0xF800-0xFFFF

    // I/O
    wire led_sel = (A == 16'hFF00);
    wire seg_sel = (A == 16'hFF10);
    wire sw_sel  = (A == 16'hFF20);

    // Data in mux
    assign DI = ram_sel ? ram[A[10:0]] :
                rom_sel ? rom[A[10:0]] :
                sw_sel  ? sw :
                8'hFF;

    // Write logic
    always @(posedge cpu_clk) begin
        if (WE) begin
            if (ram_sel)
                ram[A[10:0]] <= DO;
            else if (led_sel)
                led <= DO;
            else if (seg_sel) begin
                seg <= DO;
                an <= A[11:8]; // Use upper address bits for anode
            end
        end
    end

    // 65C02 core instantiation (correct port names)
    /*
cpu cpu_inst (
    .clk(cpu_clk),
    .RST(reset_n),
    .AD(A),
    .sync(),        // not used
    .DI(DI),
    .DO(DO),
    .WE(WE),
    .IRQ(IRQ),
    .NMI(NMI),
    .RDY(1'b1),
    .debug(1'b0)
);
*/

    // Apple 1 core instantiation (replace above for Apple 1 system)
    wire [7:0] core_led, core_seg;
    wire [3:0] core_an;
    wire core_uart_tx;
    wire [15:0] debug_cpu_addr;
    wire debug_cpu_we;
    wire [7:0] debug_cpu_data_in;
    wire [7:0] debug_cpu_data_out;
    wire [7:0] debug_uart_rx_data;
    wire [7:0] debug_tx_data;
    wire debug_tx_start;
    wire debug_tx_busy;

    apple1_core apple1_core_inst (
        .clk(clk),
        .uart_rx(1'b1), // No UART input for now
        .reset(reset),  // Center button
        .uart_tx(core_uart_tx),
        .led(core_led),
        .seg(core_seg),
        .an(core_an),
        .debug_cpu_addr(debug_cpu_addr),
        .debug_cpu_we(debug_cpu_we),
        .debug_cpu_data_in(debug_cpu_data_in),
        .debug_cpu_data_out(debug_cpu_data_out),
        .debug_uart_rx_data(debug_uart_rx_data),
        .debug_tx_data(debug_tx_data),
        .debug_tx_start(debug_tx_start),
        .debug_tx_busy(debug_tx_busy)
    );

    // Connect outputs to board
    assign led = core_led;
    assign seg = core_seg;
    assign an = core_an;

    // ROM init (Vivado: use $readmemh for demo.mem)
    initial $readmemh("demo.mem", rom);
endmodule 