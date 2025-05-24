// Testbench for writeback module
`timescale 1ns/1ps

module writeback_tb;
    // Testbench signals
    reg [63:0] ReadData;
    reg [63:0] ALUResult;
    reg [4:0] Rd;
    reg MemtoReg;
    reg RegWrite;
    
    // Output signals
    wire [63:0] WriteData;
    wire [4:0] WriteReg;
    wire RegWriteOut;
    
    // Module-level variables for tasks
    reg [31:0] test_name_reg;
    reg [63:0] exp_write_data;
    reg [4:0] exp_write_reg;
    reg exp_reg_write;
    
    // Instantiate the writeback module
    writeback dut (
        .ReadData(ReadData),
        .ALUResult(ALUResult),
        .Rd(Rd),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .WriteData(WriteData),
        .WriteReg(WriteReg),
        .RegWriteOut(RegWriteOut)
    );
    
    // Task to display writeback operation results
    task display_results;
        input [31:0] test_name;
        input [63:0] exp_WriteData;
        input [4:0] exp_WriteReg;
        input exp_RegWrite;
        begin
            // Use module-level variables
            test_name_reg = test_name;
            exp_write_data = exp_WriteData;
            exp_write_reg = exp_WriteReg;
            exp_reg_write = exp_RegWrite;
            
            $display("--- Testing %0s ---", test_name_reg);
            
            // Display Expected vs Actual for key fields
            $display("EXPECTED vs ACTUAL:");
            $display("  WriteData:     %h vs %h %s", exp_write_data, WriteData, (exp_write_data === WriteData) ? "y" : "n");
            $display("  WriteReg:      %d vs %d %s", exp_write_reg, WriteReg, (exp_write_reg === WriteReg) ? "y" : "n");
            $display("  RegWriteOut:   %1b vs %1b %s", exp_reg_write, RegWriteOut, (exp_reg_write === RegWriteOut) ? "y" : "n");
            $display("");
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        ReadData = 64'h0;
        ALUResult = 64'h0;
        Rd = 5'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for signals to stabilize
        
        // Test 1: Select ALU result (MemtoReg = 0)
        $display("--- Test 1: Select ALU result (MemtoReg = 0) ---");
        ReadData = 64'hAAAAAAAAAAAAAAAA;
        ALUResult = 64'hBBBBBBBBBBBBBBBB;
        Rd = 5'd7;
        MemtoReg = 1'b0;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Select ALU Result", 64'hBBBBBBBBBBBBBBBB, 5'd7, 1'b1);
        
        // Test 2: Select memory data (MemtoReg = 1)
        $display("--- Test 2: Select memory data (MemtoReg = 1) ---");
        ReadData = 64'hDEADBEEFDEADBEEF;
        ALUResult = 64'h1234567890ABCDEF;
        Rd = 5'd12;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Select Memory Data", 64'hDEADBEEFDEADBEEF, 5'd12, 1'b1);
        
        // Test 3: RegWrite = 0
        $display("--- Test 3: RegWrite = 0 ---");
        ReadData = 64'h9876543210FEDCBA;
        ALUResult = 64'hFEDCBA9876543210;
        Rd = 5'd31;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        
        #10; // Wait for values to stabilize
        display_results("RegWrite Disabled", 64'hFEDCBA9876543210, 5'd31, 1'b0);
        
        // Test 4: RegWrite = 0, MemtoReg = 1
        $display("--- Test 4: RegWrite = 0, MemtoReg = 1 ---");
        ReadData = 64'h1111222233334444;
        ALUResult = 64'h5555666677778888;
        Rd = 5'd15;
        MemtoReg = 1'b1;
        RegWrite = 1'b0;
        
        #10; // Wait for values to stabilize
        display_results("RegWrite Disabled, MemtoReg Enabled", 64'h1111222233334444, 5'd15, 1'b0);
        
        // Test 5: Zero register
        $display("--- Test 5: Zero register ---");
        ReadData = 64'hFFFFFFFFFFFFFFFF;
        ALUResult = 64'hEEEEEEEEEEEEEEEE;
        Rd = 5'd0;
        MemtoReg = 1'b0;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("Zero Register", 64'hEEEEEEEEEEEEEEEE, 5'd0, 1'b1);
        
        // Test 6: Corner case - all ones
        $display("--- Test 6: Corner case - all ones ---");
        ReadData = 64'hFFFFFFFFFFFFFFFF;
        ALUResult = 64'hFFFFFFFFFFFFFFFF;
        Rd = 5'b11111;
        MemtoReg = 1'b1;
        RegWrite = 1'b1;
        
        #10; // Wait for values to stabilize
        display_results("All Ones", 64'hFFFFFFFFFFFFFFFF, 5'b11111, 1'b1);
        
        // End simulation
        #10;
        $display("--- Testbench completed ---");
        $finish;
    end
    
    // Add waveform generation
    initial begin
        $dumpfile("writeback_tb.vcd");
        $dumpvars(0, writeback_tb);
    end
    
endmodule