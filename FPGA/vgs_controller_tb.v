`timescale 1ns/1ps

module vgs_controller_tb;

    // Test bench signals
    reg clk;
    reg rst_n;
    reg InVGS;
    wire OutVGS;
    wire FlybackVGS;
    
    // Clock generation parameters
    parameter CLK_PERIOD = 83.33; // 12MHz = 83.33ns period
    
    // Test case parameters
    parameter TEST_DELAY = 20;    // Standard delay between tests (cycles)
    
    // Instantiate the VGS controller
    vgs_controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .InVGS(InVGS),
        .OutVGS(OutVGS),
        .FlybackVGS(FlybackVGS)
    );
    
    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk = 1;
        #(CLK_PERIOD/2);
    end

    // Task for standard delay between tests
    task wait_cycles;
        input integer cycles;
        begin
            repeat(cycles) @(posedge clk);
        end
    endtask

    // Task to create a glitch on InVGS
    task glitch;
        input integer low_cycles;  // How many cycles InVGS stays low
        begin
            InVGS = 0;
            wait_cycles(low_cycles);
            InVGS = 1;
        end
    endtask
    
    // Test stimulus
    initial begin
        // Set up waveform dumping
        $dumpfile("vgs_controller_tb.vcd");
        $dumpvars(0, vgs_controller_tb);
        
        // Test case descriptions for waveform viewing
        $display("\n=== VGS Controller Comprehensive Test Cases ===\n");
        $display("Test 1: Basic reset and initialization");
        $display("Test 2: Normal operation with various pulse widths");
        $display("Test 3: Short pulses (edge cases)");
        $display("Test 4: EMI immunity testing");
        $display("Test 5: Rapid switching test");
        $display("\n============================================\n");

        // Initialize signals
        rst_n = 0;
        InVGS = 0;
        
        // Test 1: Reset and Initialization
        $display("Starting Test 1: Reset and Initialization");
        wait_cycles(5);
        rst_n = 1;
        wait_cycles(5);
        
        // Test 2: Normal Operation with Various Pulse Widths
        $display("Starting Test 2: Normal Operation Tests");
        
        // 2a: Medium pulse (10 cycles)
        $display("Test 2a: Medium pulse (10 cycles)");
        InVGS = 1;
        wait_cycles(10);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // 2b: Long pulse (20 cycles)
        $display("Test 2b: Long pulse (20 cycles)");
        InVGS = 1;
        wait_cycles(20);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // Test 3: Short Pulse Edge Cases
        $display("Starting Test 3: Short Pulse Tests");
        
        // 3a: Pulse too short for OutVGS (1 cycle)
        $display("Test 3a: 1-cycle pulse");
        InVGS = 1;
        wait_cycles(1);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // 3b: Pulse just short of OutVGS threshold (2 cycles)
        $display("Test 3b: 2-cycle pulse");
        InVGS = 1;
        wait_cycles(2);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // 3c: Pulse exactly at OutVGS threshold (3 cycles)
        $display("Test 3c: 3-cycle pulse");
        InVGS = 1;
        wait_cycles(3);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // Test 4: EMI Immunity Testing
        $display("Starting Test 4: EMI Immunity Tests");
        
        // 4a: Single-cycle glitch during high state
        $display("Test 4a: Single-cycle glitch");
        InVGS = 1;
        wait_cycles(5);  // Establish normal operation
        glitch(1);      // 1-cycle low glitch
        wait_cycles(5);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // 4b: Two-cycle glitch during high state
        $display("Test 4b: Two-cycle glitch");
        InVGS = 1;
        wait_cycles(5);
        glitch(2);      // 2-cycle low glitch
        wait_cycles(5);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // 4c: Multiple glitches
        $display("Test 4c: Multiple glitches");
        InVGS = 1;
        wait_cycles(5);
        glitch(1);
        wait_cycles(3);
        glitch(2);
        wait_cycles(5);
        InVGS = 0;
        wait_cycles(TEST_DELAY);
        
        // Test 5: Rapid Switching
        $display("Starting Test 5: Rapid Switching Test");
        repeat(5) begin
            InVGS = 1;
            wait_cycles(4);
            InVGS = 0;
            wait_cycles(4);
        end
        wait_cycles(TEST_DELAY);
        
        // End simulation
        $display("\nSimulation complete!");
        $finish;
    end
    
    // Monitor changes and timing
    reg [63:0] last_change_time;
    initial begin
        last_change_time = 0;
        forever @(OutVGS or FlybackVGS) begin
            if ($time != last_change_time) begin
                $display("Time=%0t: OutVGS=%b FlybackVGS=%b InVGS=%b",
                         $time, OutVGS, FlybackVGS, InVGS);
                last_change_time = $time;
            end
        end
    end

endmodule
