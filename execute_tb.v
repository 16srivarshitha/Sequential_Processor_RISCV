// Testbench for execute module
`timescale 1ns/1ps

module execute_tb;
    // Testbench signals
    reg [63:0] ReadData1;
    reg [63:0] ReadData2;
    reg [63:0] ImmExt;
    reg [4:0] Rd;
    reg [3:0] ALUOp;
    reg ALUSrc;
    
    // Control signals
    reg Branch;
    reg MemRead;
    reg MemtoReg;
    reg MemWrite;
    reg RegWrite;
    
    // Output signals
    wire [63:0] ALUResult;
    wire Zero;
    wire BranchTaken;
    wire [63:0] WriteData;
    wire [4:0] RdOut;
    
    // Control output signals
    wire MemReadOut;
    wire MemtoRegOut;
    wire MemWriteOut;
    wire RegWriteOut;
    
    // Module-level declarations for variables used in tasks
    reg [31:0] test_name_reg;
    reg [3:0] exp_alu_op;
    reg exp_alu_src;
    reg [63:0] exp_result;
    reg exp_zero;
    reg exp_branch_taken;
    
    // Test case parameters
    parameter ADD_TEST = "ADD";
    parameter SUB_TEST = "SUB";
    parameter AND_TEST = "AND";
    parameter OR_TEST = "OR";
    parameter LD_TEST = "LD";
    parameter SD_TEST = "SD";
    parameter BEQ_TEST = "BEQ";
    parameter BEQ_NOT_TAKEN_TEST = "BEQ_NOT_TAKEN";
    
    // Instantiate the execute module
    execute dut (
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        .ImmExt(ImmExt),
        .Rd(Rd),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .ALUResult(ALUResult),
        .Zero(Zero),
        .BranchTaken(BranchTaken),
        .WriteData(WriteData),
        .RdOut(RdOut),
        .MemReadOut(MemReadOut),
        .MemtoRegOut(MemtoRegOut),
        .MemWriteOut(MemWriteOut),
        .RegWriteOut(RegWriteOut)
    );
    
    // Task to display execute results with expected values
    task display_results;
        input [31:0] test_name;
        input [3:0] exp_ALUOp;
        input exp_ALUSrc;
        input [63:0] exp_ALUResult;
        input exp_Zero;
        input exp_BranchTaken;
        begin
            // Use module-level variables
            test_name_reg = test_name;
            exp_alu_op = exp_ALUOp;
            exp_alu_src = exp_ALUSrc;
            exp_result = exp_ALUResult;
            exp_zero = exp_Zero;
            exp_branch_taken = exp_BranchTaken;
            
            $display("--- Testing %0s ---", test_name_reg);
            
            // Display Expected vs Actual for key fields
            $display("EXPECTED vs ACTUAL:");
            $display("  ALUOp:        %4b vs %4b %s", exp_alu_op, ALUOp, (exp_alu_op === ALUOp) ? "y" : "n");
            $display("  ALUSrc:       %1b vs %1b %s", exp_alu_src, ALUSrc, (exp_alu_src === ALUSrc) ? "y" : "n");
            $display("  ALUResult:    %h vs %h %s", exp_result, ALUResult, (exp_result === ALUResult) ? "y" : "n");
            $display("  Zero:         %1b vs %1b %s", exp_zero, Zero, (exp_zero === Zero) ? "y" : "n");
            $display("  BranchTaken:  %1b vs %1b %s", exp_branch_taken, BranchTaken, (exp_branch_taken === BranchTaken) ? "y" : "n");
            
            // Other outputs for informational purposes
            $display("Other Outputs:");
            $display("  ReadData1: %h, ReadData2: %h, ImmExt: %h", ReadData1, ReadData2, ImmExt);
            $display("  WriteData: %h (should be same as ReadData2)", WriteData);
            $display("  RdOut: %d (should be same as Rd)", RdOut);
            $display("  Control Signals:");
            $display("    MemReadOut: %b, MemtoRegOut: %b", MemReadOut, MemtoRegOut);
            $display("    MemWriteOut: %b, RegWriteOut: %b", MemWriteOut, RegWriteOut);
            $display("");
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        ReadData1 = 64'h0;
        ReadData2 = 64'h0;
        ImmExt = 64'h0;
        Rd = 5'b0;
        ALUOp = 4'b0;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b0;
        
        // Allow for initial signal stabilization
        #10;
        
        // Test ADD instruction (R-type)
        ReadData1 = 64'h0000000000000005;
        ReadData2 = 64'h0000000000000003;
        ImmExt = 64'h0;
        Rd = 5'd1;
        ALUOp = 4'b0010;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        display_results(ADD_TEST, 4'b0010, 1'b0, 64'h0000000000000008, 1'b0, 1'b0);
        
        // Test SUB instruction (R-type)
        ReadData1 = 64'h000000000000000A;
        ReadData2 = 64'h0000000000000004;
        ImmExt = 64'h0;
        Rd = 5'd4;
        ALUOp = 4'b0110;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        display_results(SUB_TEST, 4'b0110, 1'b0, 64'h0000000000000006, 1'b0, 1'b0);
        
        // Test AND instruction (R-type)
        ReadData1 = 64'h00000000000000FF;
        ReadData2 = 64'h000000000000000F;
        ImmExt = 64'h0;
        Rd = 5'd7;
        ALUOp = 4'b0111;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        display_results(AND_TEST, 4'b0111, 1'b0, 64'h000000000000000F, 1'b0, 1'b0);
        
        // Test OR instruction (R-type)
        ReadData1 = 64'h0000000000000050;
        ReadData2 = 64'h000000000000000F;
        ImmExt = 64'h0;
        Rd = 5'd10;
        ALUOp = 4'b0001;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        display_results(OR_TEST, 4'b0001, 1'b0, 64'h000000000000005F, 1'b0, 1'b0);
        
        // Test LD instruction (I-type)
        ReadData1 = 64'h0000000000000100;
        ReadData2 = 64'h0;
        ImmExt = 64'h0000000000000008;
        Rd = 5'd13;
        ALUOp = 4'b0000;
        ALUSrc = 1'b1;
        Branch = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        display_results(LD_TEST, 4'b0000, 1'b1, 64'h0000000000000108, 1'b0, 1'b0);
        
        // Test SD instruction (S-type)
        ReadData1 = 64'h0000000000000100;
        ReadData2 = 64'hDEADBEEFDEADBEEF;
        ImmExt = 64'h0000000000000010;
        Rd = 5'd0;
        ALUOp = 4'b0000;
        ALUSrc = 1'b1;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b1;
        RegWrite = 1'b0;
        #10;
        display_results(SD_TEST, 4'b0000, 1'b1, 64'h0000000000000110, 1'b0, 1'b0);
        
        // Test BEQ instruction (B-type) - branch taken
        ReadData1 = 64'h0000000000000025;
        ReadData2 = 64'h0000000000000025;
        ImmExt = 64'h0000000000000010;
        Rd = 5'd0;
        ALUOp = 4'b0110;
        ALUSrc = 1'b0;
        Branch = 1'b1;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b0;
        #10;
        display_results(BEQ_TEST, 4'b0110, 1'b0, 64'h0000000000000000, 1'b1, 1'b1);
        
        // Test BEQ instruction (B-type) - branch not taken
        ReadData1 = 64'h0000000000000025;
        ReadData2 = 64'h0000000000000026;
        ImmExt = 64'h0000000000000010;
        Rd = 5'd0;
        ALUOp = 4'b0110;
        ALUSrc = 1'b0;
        Branch = 1'b1;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b0;
        #10;
        display_results(BEQ_NOT_TAKEN_TEST, 4'b0110, 1'b0, 64'hFFFFFFFFFFFFFFFF, 1'b0, 1'b0);
        
        // Test control signal forwarding
        $display("--- Testing Control Signal Forwarding ---");
        $display("Setting MemRead=1, MemtoReg=1, MemWrite=0, RegWrite=1");
        ReadData1 = 64'h0000000000000100;
        ReadData2 = 64'h0000000000000200;
        ImmExt = 64'h0000000000000010;
        Rd = 5'd25;
        ALUOp = 4'b0010;
        ALUSrc = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b1;
        MemtoReg = 1'b1;
        MemWrite = 1'b0;
        RegWrite = 1'b1;
        #10;
        $display("Control Signal Forwarding Check:");
        $display("  MemRead:    %b -> %b %s", MemRead, MemReadOut, (MemRead === MemReadOut) ? "y" : "n");
        $display("  MemtoReg:   %b -> %b %s", MemtoReg, MemtoRegOut, (MemtoReg === MemtoRegOut) ? "y" : "n");
        $display("  MemWrite:   %b -> %b %s", MemWrite, MemWriteOut, (MemWrite === MemWriteOut) ? "y" : "n");
        $display("  RegWrite:   %b -> %b %s", RegWrite, RegWriteOut, (RegWrite === RegWriteOut) ? "y" : "n");
        $display("  Rd:         %d -> %d %s", Rd, RdOut, (Rd === RdOut) ? "y" : "n");
        $display("");
        
        // End simulation
        #10;
        $display("--- Testbench completed ---");
        $finish;
    end
    
    // Add waveform generation
    initial begin
        $dumpfile("execute_tb.vcd");
        $dumpvars(0, execute_tb);
    end
    
endmodule