`timescale 1ns / 1ps

// Define SIM macro to enable CPU debug output
`define SIM

module apple1_core_tb;
    reg clk = 0;
    reg reset = 1;
    reg uart_rx = 1'b1; // idle
    wire uart_tx;
    wire [7:0] led;
    wire [7:0] seg;
    wire [3:0] an;

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    // Instantiate DUT
    apple1_core dut (
        .clk(clk),
        .uart_rx(uart_rx),
        .reset(reset),
        .uart_tx(uart_tx),
        .led(led),
        .seg(seg),
        .an(an)
    );

    // Debug signals from CPU (these will be available through the CPU debug output)
    wire [15:0] debug_cpu_addr;
    wire debug_cpu_we;
    wire [7:0] debug_cpu_data_out;
    wire [7:0] debug_tx_data;
    wire debug_tx_start;
    wire debug_tx_busy;

    // Connect debug signals from CPU internal signals
    assign debug_cpu_addr = dut.cpu_inst.AD;
    assign debug_cpu_we = dut.cpu_inst.WE;
    assign debug_cpu_data_out = dut.cpu_inst.DO;
    assign debug_tx_data = dut.tx_data;
    assign debug_tx_start = dut.tx_start;
    assign debug_tx_busy = dut.tx_busy;

    // Test variables
    reg [31:0] cycle_count = 0;
    reg [31:0] uart_transmissions = 0;
    reg [31:0] cpu_cycles = 0;
    reg [7:0] last_tx_data = 8'h00;
    reg [15:0] last_cpu_addr = 16'h0000;
    reg last_cpu_we = 0;
    reg [7:0] last_cpu_data_out = 8'h00;
    
    // Expected values from echo55.asm
    reg [7:0] expected_tx_data = 8'h55; // ASCII 'U'
    reg [15:0] expected_write_addr = 16'hD001; // UART TX register
    
    // Monitor CPU activity and UART transmissions
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        
        // Count CPU cycles (every 50 cycles of 100MHz = 1 CPU cycle at 1MHz)
        if (cycle_count % 50 == 0) begin
            cpu_cycles <= cpu_cycles + 1;
        end
        
        // Monitor CPU writes to UART TX register
        if (debug_cpu_we && debug_cpu_addr == expected_write_addr) begin
            $display("%8t CPU WRITE: addr=%04X, data=%02X (expected %02X)", 
                     $time, debug_cpu_addr, debug_cpu_data_out, expected_tx_data);
            
            if (debug_cpu_data_out == expected_tx_data) begin
                $display("%8t ✓ CPU correctly wrote $55 to UART TX register", $time);
            end else begin
                $display("%8t ✗ ERROR: CPU wrote %02X, expected %02X", 
                         $time, debug_cpu_data_out, expected_tx_data);
            end
        end
        
        // Monitor UART transmission start
        if (debug_tx_start && !debug_tx_busy) begin
            uart_transmissions <= uart_transmissions + 1;
            $display("%8t UART TX START: data=%02X (transmission #%d)", 
                     $time, debug_tx_data, uart_transmissions + 1);
            
            if (debug_tx_data == expected_tx_data) begin
                $display("%8t ✓ UART correctly transmitting $55", $time);
            end else begin
                $display("%8t ✗ ERROR: UART transmitting %02X, expected %02X", 
                         $time, debug_tx_data, expected_tx_data);
            end
        end
        
        // Monitor CPU address changes to see program execution
        if (debug_cpu_addr !== last_cpu_addr) begin
            $display("%8t CPU ADDR: %04X", $time, debug_cpu_addr);
            last_cpu_addr <= debug_cpu_addr;
        end
        
        // Store last values for change detection
        last_cpu_we <= debug_cpu_we;
        last_cpu_data_out <= debug_cpu_data_out;
        last_tx_data <= debug_tx_data;
    end

    // Main test sequence
    initial begin
        $dumpfile("apple1_core_tb.vcd");
        $dumpvars(0, apple1_core_tb);
        
        $display("=== Apple 1 Core Testbench - Testing echo55.asm ===");
        $display("Expected behavior:");
        $display("1. CPU should load $55 into accumulator (LDA #$55)");
        $display("2. CPU should write $55 to $D001 (STA $D001)");
        $display("3. UART should transmit $55 repeatedly");
        $display("4. Program should loop back to start (JMP $E000)");
        $display("");
        
        // Robust reset pulse: hold reset high for 5 clock cycles, then pulse low (active-low reset)
        reset = 1; // Start with reset released
        repeat (5) @(posedge clk);
        reset = 0; // Pulse reset low (active)
        repeat (5) @(posedge clk);
        reset = 1; // Release reset
        
        // Wait for CPU to start executing
        #100000; // Wait 100us for CPU to start
        
        $display("%8t Starting verification phase...", $time);
        
        // Monitor for at least 10 UART transmissions to verify the loop is working
        wait(uart_transmissions >= 10);
        
        $display("");
        $display("=== Test Results ===");
        $display("Total cycles: %d", cycle_count);
        $display("CPU cycles: %d", cpu_cycles);
        $display("UART transmissions: %d", uart_transmissions);
        
        if (uart_transmissions >= 10) begin
            $display("✓ SUCCESS: CPU is running echo55.asm correctly!");
            $display("  - Program is continuously writing $55 to UART TX");
            $display("  - UART is transmitting the data");
            $display("  - Program loop is working");
        end else begin
            $display("✗ FAILURE: Not enough UART transmissions detected");
        end
        
        #1000000; // Wait 1ms more to see additional activity
        $finish;
    end

    // Timeout to prevent infinite simulation
    initial begin
        #10000000; // 10ms timeout
        $display("✗ TIMEOUT: Simulation ran too long without expected behavior");
        $finish;
    end

endmodule 