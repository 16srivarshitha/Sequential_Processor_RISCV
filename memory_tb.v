// Testbench for memory module
`timescale 1ns/1ps

module memory_tb;
    // Testbench signals
    reg clk;
    reg reset;
    reg [63:0] ALUResult;
    reg [63:0] WriteData;
    reg [4:0] Rd;
    reg Zero;
    reg BranchTaken;
    reg MemRead;
    reg MemWrite;
    reg MemtoReg;
    reg RegWrite;
    
    // Output signals
    wire [63:0] ReadData;
    wire [63:0] ALUResultOut;
    wire [4:0] RdOut;
    wire BranchTakenOut;
    wire MemtoRegOut;
    wire RegWriteOut;
    
    // Module-level variables for tasks
    reg [31:0] test_name_reg;
    reg [63:0] exp_read_data;
    reg exp_branch_taken;
    
    // Instantiate the memory module
    memory dut (
        .clk(clk),
        .reset(reset),
        .ALUResult(ALUResult),
        .WriteData(WriteData),
        .Rd(Rd),
        .Zero(Zero),
        .BranchTaken(BranchTaken),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .ReadData(ReadData),
        .ALUResultOut(ALUResultOut),
        .RdOut(RdOut),
        .BranchTakenOut(BranchTakenOut),
        .MemtoRegOut(MemtoRegOut),
        .RegWriteOut(RegWriteOut)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end
    
    // Task to display memory operation results
    task display_results;
        input [31:0] test_name;
        input [63:0] exp_ReadData;
        input exp_BranchTaken;
        begin
            // Use module-level variables
            test_name_reg = test_name;
            exp_read_data = exp_ReadData;
            exp_branch_taken = exp_BranchTaken;
            
            $display("--- Testing %0s ---", test_name_reg);
            
            // Display Expected vs Actual for key fields
            $display("EXPECTED vs ACTUAL:");
            $display("  ReadData:      %h vs %h %s", exp_read_data, ReadData, (exp_read_data === ReadData) ? "y" : "n");
            $display("  BranchTaken:   %1b vs %1b %s", exp_branch_taken, BranchTakenOut, (exp_branch_taken === BranchTakenOut) ? "y" : "n");
            
            // Other outputs for informational purposes
            $display("Other Outputs:");
            $display("  ALUResult:     %h -> %h %s", ALUResult, ALUResultOut, (ALUResult === ALUResultOut) ? "y" : "n");
            $display("  Rd:            %d -> %d %s", Rd, RdOut, (Rd === RdOut) ? "y" : "n");
            $display("  Control Signals:");
            $display("    MemtoReg:    %b -> %b %s", MemtoReg, MemtoRegOut, (MemtoReg === MemtoRegOut) ? "y" : "n");
            $display("    RegWrite:    %b -> %b %s", RegWrite, RegWriteOut, (RegWrite === RegWriteOut) ? "y" : "n");
            $display("");
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        ALUResult = 64'h0;
        WriteData = 64'h0;
        Rd = 5'b0;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        // Apply reset
        #15;
        reset = 0;
        #10;
        
        // Test 1: Write to memory
        $display("--- Test 1: Write to memory address 0x10 ---");
        ALUResult = 64'h0000000000000010; // Memory address 0x10 (will be divided by 8 internally)
        WriteData = 64'hDEADBEEFDEADBEEF;
        Rd = 5'd15;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Test 2: Read from memory
        $display("--- Test 2: Read from memory address 0x10 ---");
        ALUResult = 64'h0000000000000010; // Same address as write
        WriteData = 64'h0;
        Rd = 5'd13;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Memory Read", 64'hDEADBEEFDEADBEEF, 1'b0);
        
        // Test 3: Write to a different address
        $display("--- Test 3: Write to memory address 0x20 ---");
        ALUResult = 64'h0000000000000020; // Memory address 0x20
        WriteData = 64'h1234567890ABCDEF;
        Rd = 5'd0;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Test 4: Read from the new address
        $display("--- Test 4: Read from memory address 0x20 ---");
        ALUResult = 64'h0000000000000020;
        WriteData = 64'h0;
        Rd = 5'd14;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Memory Read 2", 64'h1234567890ABCDEF, 1'b0);
        
        // Test 5: Test branch signal propagation
        $display("--- Test 5: Test branch signal propagation ---");
        ALUResult = 64'h0000000000000030;
        WriteData = 64'h0;
        Rd = 5'd0;
        Zero = 1'b1;
        BranchTaken = 1'b1;
        MemRead = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for values to stabilize
        display_results("Branch Signal Test", 64'h0, 1'b1);
        
        // Test 6: Test control signal propagation
        $display("--- Test 6: Test control signal propagation ---");
        ALUResult = 64'h0000000000000040;
        WriteData = 64'h0;
        Rd = 5'd20;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Control Signal Test", 64'h0, 1'b0);
        
        // Test 7: Test memory at boundary address 0
        $display("--- Test 7: Test memory at boundary address 0 ---");
        ALUResult = 64'h0000000000000000;
        WriteData = 64'hAAAAAAAAAAAAAAAA;
        Rd = 5'd2;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Read back from address 0
        MemWrite = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Memory Boundary Test (0)", 64'hAAAAAAAAAAAAAAAA, 1'b0);
        
        // Test 8: Test memory at upper boundary (1023)
        $display("--- Test 8: Test memory at upper boundary (1023) ---");
        ALUResult = 64'h0000000000001FF8; // 1023 * 8
        WriteData = 64'h5555555555555555;
        Rd = 5'd3;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Read back from upper boundary
        MemWrite = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Memory Boundary Test (1023)", 64'h5555555555555555, 1'b0);
        
        // Test 9: Test out-of-bounds access
        $display("--- Test 9: Test out-of-bounds access ---");
        ALUResult = 64'h0000000000002000; // Beyond 1024 * 8
        WriteData = 64'h0;
        Rd = 5'd4;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Out-of-Bounds Test", 64'h0, 1'b0); // Should return 0
        
        // Test 10: Reset behavior test
        $display("--- Test 10: Reset behavior test ---");
        // First read current value at address 0
        ALUResult = 64'h0000000000000000;
        WriteData = 64'h0;
        Rd = 5'd5;
        Zero = 1'b0;
        BranchTaken = 1'b0;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        
        // Store a new value at address 0
        ALUResult = 64'h0000000000000000;
        WriteData = 64'hFFFFFFFFFFFFFFFF;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Read back to confirm value was written
        MemWrite = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Pre-Reset Memory Check", 64'hFFFFFFFFFFFFFFFF, 1'b0);
        
        // Apply reset
        reset = 1'b1;
        #10;
        reset = 1'b0;
        #10;
        
        // Read back after reset
        ALUResult = 64'h0000000000000000;
        MemRead = 1'b1;
        MemWrite = 1'b0;
        
        #10; // Wait for values to stabilize
        display_results("Reset Behavior Test", 64'h0, 1'b0); // Should be reset to 0
        
        // Test 11: Simulate load (ld) instruction
        $display("--- Test 11: Simulate load (ld) instruction ---");
        // First write a value to memory
        ALUResult = 64'h0000000000000050; // Address for ld
        WriteData = 64'hABCDEF0123456789;
        MemRead = 1'b0;
        MemWrite = 1'b1;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for clock edge
        
        // Now perform load operation
        MemWrite = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1; // Tell writeback to use memory data
        RegWrite = 1'b1; // Enable register writing
        Rd = 5'd10; // Target register
        
        #10; // Wait for values to stabilize
        display_results("Load Instruction Test", 64'hABCDEF0123456789, 1'b0);
        
        // Test 12: Simulate store (sd) instruction
        $display("--- Test 12: Simulate store (sd) instruction ---");
        ALUResult = 64'h0000000000000060; // Address for sd
        WriteData = 64'h9876543210FEDCBA; // Value to store
        MemRead = 1'b0;
        MemWrite = 1'b1; // Enable memory writing
        MemtoReg = 1'b0;
        RegWrite = 1'b0; // Disable register writing
        
        #10; // Wait for clock edge
        
        // Verify the store by reading back
        MemWrite = 1'b0;
        MemRead = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Store Instruction Test", 64'h9876543210FEDCBA, 1'b0);
        
        // End simulation
        #10;
        $display("--- Testbench completed ---");
        $finish;
    end
    
    // Add waveform generation
    initial begin
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, memory_tb);
    end
    
endmodule