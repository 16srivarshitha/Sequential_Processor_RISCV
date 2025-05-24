// Revised testbench for Icarus Verilog compatibility
`timescale 1ns/1ps

module decode_tb;
    // Module-level declarations for variables used in tasks
    reg [6:0] opcode;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] instr_name_reg;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg [31:0] Instr;
    reg ExtRegWrite;
    wire RegWrite;
    reg [4:0] WriteReg;
    reg [63:0] WriteData;
    
    // Output signals
    wire [63:0] ReadData1;
    wire [63:0] ReadData2;
    wire [63:0] ImmExt;
    wire [4:0] Rd;
    wire Branch, MemRead, MemtoReg;
    wire [3:0] ALUOp;
    wire MemWrite, ALUSrc, RegDst;
    
    // Instruction test cases
    parameter ADD_INSTR = 32'h003100B3;    // add x1, x2, x3
    parameter SUB_INSTR = 32'h40628233;    // sub x4, x5, x6
    parameter AND_INSTR = 32'h00947433;    // and x8, x8, x9 - FIXED: Changed to put result in x8 instead of x7
    parameter OR_INSTR = 32'h00C5E533;     // or x10, x11, x12
    parameter LD_INSTR = 32'h00873683;     // ld x13, 8(x14)
    parameter SD_INSTR = 32'h00F83823;     // sd x15, 16(x16)
    parameter BEQ_INSTR = 32'h01280863;    // beq x17, x18, 16
    
    // Instantiate the decode module
    decode dut (
        .clk(clk),
        .reset(reset),
        .Instr(Instr),
        .ExtRegWrite(ExtRegWrite),
        .RegWrite(RegWrite),
        .WriteReg(WriteReg),
        .WriteData(WriteData),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        .ImmExt(ImmExt),
        .Rd(Rd),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegDst(RegDst)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end
    
    // Modified task to display decode results with expected values
    // Now checking rd against Rd (not rd) for S-type and B-type instructions
    task display_results;
        input [31:0] instr_name;
        input [6:0] exp_opcode;
        input [4:0] exp_rs1;
        input [4:0] exp_rs2;
        input [4:0] exp_rd;
        input [3:0] exp_ALUOp;
        input exp_ALUSrc;
        begin
            // Use module-level variables
            instr_name_reg = instr_name;
            opcode = Instr[6:0];
            rd = Instr[11:7];
            rs1 = Instr[19:15];
            rs2 = Instr[24:20];
            
            $display("--- Testing %0s ---", instr_name_reg);
            $display("Instruction: %h", Instr);
            
            // Display Expected vs Actual for key fields
            $display("EXPECTED vs ACTUAL:");
            $display("  Opcode: %7b vs %7b %s", exp_opcode, opcode, (exp_opcode === opcode) ? "y" : "n");
            $display("  rs1:    %5d vs %5d %s", exp_rs1, rs1, (exp_rs1 === rs1) ? "y" : "n");
            $display("  rs2:    %5d vs %5d %s", exp_rs2, rs2, (exp_rs2 === rs2) ? "y" : "n");
            $display("  rd (output): %5d vs %5d %s", exp_rd, Rd, (exp_rd === Rd) ? "y" : "n");
            $display("  ALUOp:  %4b vs %4b %s", exp_ALUOp, ALUOp, (exp_ALUOp === ALUOp) ? "y" : "n");
            $display("  ALUSrc: %1b vs %1b %s", exp_ALUSrc, ALUSrc, (exp_ALUSrc === ALUSrc) ? "y" : "n");
            
            // Other outputs for informational purposes
            $display("Other Outputs:");
            $display("  ReadData1: %h, ReadData2: %h", ReadData1, ReadData2);
            $display("  ImmExt: %h", ImmExt);
            $display("  Control Signals:");
            $display("    Branch: %b, MemRead: %b, MemtoReg: %b", Branch, MemRead, MemtoReg);
            $display("    MemWrite: %b, RegDst: %b", MemWrite, RegDst);
            $display("    RegWrite (internal): %b", RegWrite);
            $display("");
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        Instr = 32'h0;
        ExtRegWrite = 0;
        WriteReg = 5'b0;
        WriteData = 64'h0;
        
        // Apply reset
        #10;
        reset = 0;
        #10;
        
        // Test add instruction (R-type)
        Instr = ADD_INSTR;
        #10;
        // add x1, x2, x3 (0000000 00011 00010 000 00001 0110011)
        display_results("add x1, x2, x3", 7'b0110011, 5'd2, 5'd3, 5'd1, 4'b0010, 1'b0);
        
        // Test sub instruction (R-type)
        Instr = SUB_INSTR;
        #10;
        // sub x4, x5, x6 (0100000 00110 00101 000 00100 0110011)
        display_results("sub x4, x5, x6", 7'b0110011, 5'd5, 5'd6, 5'd4, 4'b0110, 1'b0);
        
        // Test and instruction (R-type) - FIXED: was using wrong rd value
        Instr = AND_INSTR;
        #10;
        // and x8, x8, x9 (0000000 01001 01000 111 01000 0110011)
        display_results("and x8, x8, x9", 7'b0110011, 5'd8, 5'd9, 5'd8, 4'b0111, 1'b0);
        
        // Test or instruction (R-type)
        Instr = OR_INSTR;
        #10;
        // or x10, x11, x12 (0000000 01100 01011 110 01010 0110011)
        display_results("or x10, x11, x12", 7'b0110011, 5'd11, 5'd12, 5'd10, 4'b0001, 1'b0);
        
        // Test ld instruction (I-type) - FIXED: Now properly expect rs2=8 (though it's not used)
        Instr = LD_INSTR;
        #10;
        // ld x13, 8(x14) (0000000 01000 01110 011 01101 0000011)
        display_results("ld x13, 8(x14)", 7'b0000011, 5'd14, 5'd8, 5'd13, 4'b0000, 1'b1);
        
        // Test sd instruction (S-type)
        Instr = SD_INSTR;
        #10;
        // sd x15, 16(x16) (0000001 01111 10000 011 00000 0100011)
        display_results("sd x15, 16(x16)", 7'b0100011, 5'd16, 5'd15, 5'd0, 4'b0000, 1'b1);
        
        // Test beq instruction (B-type)
        Instr = BEQ_INSTR;
        #10;
        // beq x17, x18, 16 (0000001 10010 10001 000 00100 1100011)
        display_results("beq x17, x18, 16", 7'b1100011, 5'd16, 5'd18, 5'd0, 4'b0001, 1'b0);
        
        // Test register write functionality
        $display("--- Testing Register Write Functionality ---");
        // Initial value of register x20
        $display("Initial value of x20: %h", dut.registers[20]);
        
        // Write 0xDEADBEEF to register x20
        ExtRegWrite = 1;
        WriteReg = 5'd20;
        WriteData = 64'hDEADBEEF_DEADBEEF;
        #10;
        
        // Verify the write
        $display("After write, value of x20: %h", dut.registers[20]);
        $display("Expected value of x20: %h", 64'hDEADBEEF_DEADBEEF);
        
        // FIXED: Test reading from the written register using a proper instruction
        // Using an instruction that actually uses x20 as rs1 (bits [19:15])
        Instr = 32'h014A3A13; // A made-up instruction with rs1=x20 (01010 in bits 19:15)
        #10;
        $display("ReadData1 should reflect x20's value:");
        $display("  Expected: %h", 64'hDEADBEEF_DEADBEEF);
        $display("  Actual:   %h %s", ReadData1, (ReadData1 === 64'hDEADBEEF_DEADBEEF) ? "y" : "n");
        
        // Test writing to x0 (should remain 0)
        ExtRegWrite = 1;
        WriteReg = 5'd0;
        WriteData = 64'hFFFFFFFF_FFFFFFFF;
        #10;
        $display("Value of x0 after attempted write:");
        $display("  Expected: %h (should always be 0)", 64'h0);
        $display("  Actual:   %h %s", dut.registers[0], (dut.registers[0] === 64'h0) ? "y" : "n");
        
        // End simulation
        #10;
        $display("--- Testbench completed ---");
        $finish;
    end
    
    // Add waveform generation
    initial begin
        $dumpfile("decode_tb.vcd");
        $dumpvars(0, decode_tb);
    end
    
endmodule