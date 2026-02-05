module multi_cycle_processor_tb;

    reg clk;
    reg reset;
    
    // Instantiate the processor
    multi_cycle_processor dut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $dumpfile("multi_cycle_processor.vcd");
        $dumpvars(0, multi_cycle_processor_tb);
        
        // Initialize
        reset = 1;
        #20;
        reset = 0;
        
        // Run for enough cycles to complete all instructions
        // Assuming worst case: 10 instructions * 5 cycles each = 50 cycles
        #1000;
        
        // Display final register values
        $display("\n=== Final Register Values ===");
        $display("x0  = %d", dut.reg_file.registers[0]);
        $display("x1  = %d", dut.reg_file.registers[1]);
        $display("x2  = %d", dut.reg_file.registers[2]);
        $display("x3  = %d", dut.reg_file.registers[3]);
        $display("x4  = %d", dut.reg_file.registers[4]);
        $display("x5  = %d", dut.reg_file.registers[5]);
        $display("x6  = %d", dut.reg_file.registers[6]);
        $display("x7  = %d", dut.reg_file.registers[7]);
        $display("x8  = %d", dut.reg_file.registers[8]);
        $display("x9  = %d", dut.reg_file.registers[9]);
        $display("x10 = %d", dut.reg_file.registers[10]);
        
        // Display memory contents
        $display("\n=== Data Memory Contents (first 16 words) ===");
        $display("Addr 4096: %h", {dut.memory.memory[4103], dut.memory.memory[4102], 
                                    dut.memory.memory[4101], dut.memory.memory[4100],
                                    dut.memory.memory[4099], dut.memory.memory[4098],
                                    dut.memory.memory[4097], dut.memory.memory[4096]});
        $display("Addr 4104: %h", {dut.memory.memory[4111], dut.memory.memory[4110],
                                    dut.memory.memory[4109], dut.memory.memory[4108],
                                    dut.memory.memory[4107], dut.memory.memory[4106],
                                    dut.memory.memory[4105], dut.memory.memory[4104]});
        
        // Performance metrics
        $display("\n=== Performance Metrics ===");
        $display("Total cycles: %d", $time / 10);
        $display("PC final value: %d", dut.PC);
        
        $finish;
    end
    
    // Monitor state transitions
    always @(posedge clk) begin
        $display("Time=%0t State=%d PC=%d IR=%h", 
                 $time, dut.fsm.state, dut.PC, dut.IR);
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule