`timescale 1ns/1ps

module memory_tb;
    reg clk, reset;
    reg [63:0] ALUResult, WriteData;
    reg [4:0] Rd;
    reg Zero, BranchTaken, MemRead, MemWrite, MemtoReg, RegWrite;
    
    wire [63:0] ReadData, ALUResultOut;
    wire [4:0] RdOut;
    wire BranchTakenOut, MemtoRegOut, RegWriteOut;
    
    // Instantiate DUT
    memory dut (
        .clk(clk), .reset(reset),
        .ALUResult(ALUResult), .WriteData(WriteData), .Rd(Rd),
        .Zero(Zero), .BranchTaken(BranchTaken),
        .MemRead(MemRead), .MemWrite(MemWrite),
        .MemtoReg(MemtoReg), .RegWrite(RegWrite),
        .ReadData(ReadData), .ALUResultOut(ALUResultOut),
        .RdOut(RdOut), .BranchTakenOut(BranchTakenOut),
        .MemtoRegOut(MemtoRegOut), .RegWriteOut(RegWriteOut)
    );
    
    // Clock: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Check task
    task check_memory;
        input [127:0] name;
        input [63:0] exp_data;
        input exp_branch;
        reg pass;
        begin
            pass = (ReadData === exp_data) && (BranchTakenOut === exp_branch);
            $display("--- %0s ---", name);
            $display("ReadData=%h(%h) | Branch=%b(%b) | %s",
                     ReadData, exp_data, BranchTakenOut, exp_branch,
                     pass ? "PASS" : "FAIL");
        end
    endtask
    
    // Test sequence
    initial begin
        reset = 1;
        {ALUResult, WriteData, Rd} = {64'd0, 64'd0, 5'd0};
        {Zero, BranchTaken, MemRead, MemWrite, MemtoReg, RegWrite} = 6'b0;
        
        #15 reset = 0;
        #10;
        
        // Write to address 0x10
        ALUResult = 64'h10; WriteData = 64'hDEADBEEFDEADBEEF;
        MemWrite = 1; Rd = 5'd15;
        #10;
        
        // Read from address 0x10
        MemWrite = 0; MemRead = 1; MemtoReg = 1; RegWrite = 1;
        Rd = 5'd13;
        #10 check_memory("Read 0x10", 64'hDEADBEEFDEADBEEF, 1'b0);
        
        // Write to address 0x20
        ALUResult = 64'h20; WriteData = 64'h1234567890ABCDEF;
        MemRead = 0; MemWrite = 1; MemtoReg = 0; RegWrite = 0;
        #10;
        
        // Read from address 0x20
        MemWrite = 0; MemRead = 1; MemtoReg = 1; RegWrite = 1;
        Rd = 5'd14;
        #10 check_memory("Read 0x20", 64'h1234567890ABCDEF, 1'b0);
        
        // Branch signal test
        ALUResult = 64'h30; BranchTaken = 1; MemRead = 0;
        MemWrite = 0; RegWrite = 0;
        #10 check_memory("Branch signal", 64'd0, 1'b1);
        
        // Boundary test: address 0
        ALUResult = 64'h0; WriteData = 64'hAAAAAAAAAAAAAAAA;
        MemWrite = 1;
        #10;
        MemWrite = 0; MemRead = 1;
        #10 check_memory("Boundary addr 0", 64'hAAAAAAAAAAAAAAAA, 1'b0);
        
        // Boundary test: address 1023*8
        ALUResult = 64'h1FF8; WriteData = 64'h5555555555555555;
        MemRead = 0; MemWrite = 1;
        #10;
        MemWrite = 0; MemRead = 1;
        #10 check_memory("Boundary addr 1023", 64'h5555555555555555, 1'b0);
        
        // Out of bounds test
        ALUResult = 64'h2000; MemRead = 1; MemWrite = 0;
        #10 check_memory("Out of bounds", 64'd0, 1'b0);
        
        // Reset test
        ALUResult = 64'h0; WriteData = 64'hFFFFFFFFFFFFFFFF;
        MemRead = 0; MemWrite = 1;
        #10;
        reset = 1;
        #10 reset = 0;
        #10;
        MemWrite = 0; MemRead = 1;
        #10 check_memory("After reset", 64'd0, 1'b0);
        
        #10;
        $display("Memory testbench completed");
        $finish;
    end
    
    initial begin
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, memory_tb);
    end

endmodule