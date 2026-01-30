`timescale 1ns/1ps

module execute_tb;
    reg [63:0] ReadData1, ReadData2, ImmExt;
    reg [4:0] Rd;
    reg [3:0] ALUOp;
    reg ALUSrc, Branch, MemRead, MemtoReg, MemWrite, RegWrite;
    
    wire [63:0] ALUResult, WriteData;
    wire Zero, BranchTaken;
    wire [4:0] RdOut;
    wire MemReadOut, MemtoRegOut, MemWriteOut, RegWriteOut;
    
    // Instantiate DUT
    execute dut (
        .ReadData1(ReadData1), .ReadData2(ReadData2), .ImmExt(ImmExt),
        .Rd(Rd), .ALUOp(ALUOp), .ALUSrc(ALUSrc),
        .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg),
        .MemWrite(MemWrite), .RegWrite(RegWrite),
        .ALUResult(ALUResult), .Zero(Zero), .BranchTaken(BranchTaken),
        .WriteData(WriteData), .RdOut(RdOut),
        .MemReadOut(MemReadOut), .MemtoRegOut(MemtoRegOut),
        .MemWriteOut(MemWriteOut), .RegWriteOut(RegWriteOut)
    );
    
    // Check task
    task check_execute;
        input [127:0] name;
        input [3:0] exp_aluop;
        input exp_alusrc;
        input [63:0] exp_result;
        input exp_zero;
        input exp_branch;
        reg pass;
        begin
            pass = (ALUOp === exp_aluop) && (ALUSrc === exp_alusrc) &&
                   (ALUResult === exp_result) && (Zero === exp_zero) &&
                   (BranchTaken === exp_branch);
            
            $display("--- %0s ---", name);
            $display("ALUOp=%b(%b) | ALUSrc=%b(%b) | Result=%h(%h)",
                     ALUOp, exp_aluop, ALUSrc, exp_alusrc, ALUResult, exp_result);
            $display("Zero=%b(%b) | Branch=%b(%b) | %s",
                     Zero, exp_zero, BranchTaken, exp_branch, pass ? "PASS" : "FAIL");
            $display("");
        end
    endtask
    
    // Test stimulus
    initial begin
        // Initialize
        {ReadData1, ReadData2, ImmExt} = {64'd0, 64'd0, 64'd0};
        {Rd, ALUOp} = {5'd0, 4'd0};
        {ALUSrc, Branch, MemRead, MemtoReg, MemWrite, RegWrite} = 6'b0;
        #10;
        
        // Test ADD
        ReadData1 = 64'h5; ReadData2 = 64'h3; ALUOp = 4'b0010;
        ALUSrc = 0; Rd = 5'd1; RegWrite = 1;
        #10 check_execute("ADD x1,x2,x3", 4'b0010, 1'b0, 64'h8, 1'b0, 1'b0);
        
        // Test SUB
        ReadData1 = 64'hA; ReadData2 = 64'h4; ALUOp = 4'b0110;
        #10 check_execute("SUB x4,x5,x6", 4'b0110, 1'b0, 64'h6, 1'b0, 1'b0);
        
        // Test AND
        ReadData1 = 64'hFF; ReadData2 = 64'h0F; ALUOp = 4'b0111;
        #10 check_execute("AND x8,x8,x9", 4'b0111, 1'b0, 64'h0F, 1'b0, 1'b0);
        
        // Test OR
        ReadData1 = 64'h50; ReadData2 = 64'h0F; ALUOp = 4'b0001;
        #10 check_execute("OR x10,x11,x12", 4'b0001, 1'b0, 64'h5F, 1'b0, 1'b0);
        
        // Test LD (immediate)
        ReadData1 = 64'h100; ImmExt = 64'h8; ALUOp = 4'b0000;
        ALUSrc = 1; MemRead = 1; MemtoReg = 1;
        #10 check_execute("LD x13,8(x14)", 4'b0000, 1'b1, 64'h108, 1'b0, 1'b0);
        
        // Test SD (immediate)
        ReadData1 = 64'h100; ReadData2 = 64'hDEADBEEF; ImmExt = 64'h10;
        MemRead = 0; MemWrite = 1; MemtoReg = 0; RegWrite = 0;
        #10 check_execute("SD x15,16(x16)", 4'b0000, 1'b1, 64'h110, 1'b0, 1'b0);
        
        // Test BEQ taken
        ReadData1 = 64'h25; ReadData2 = 64'h25; ALUOp = 4'b0110;
        ALUSrc = 0; Branch = 1; MemWrite = 0;
        #10 check_execute("BEQ taken", 4'b0110, 1'b0, 64'h0, 1'b1, 1'b1);
        
        // Test BEQ not taken
        ReadData1 = 64'h25; ReadData2 = 64'h26;
        #10 check_execute("BEQ not taken", 4'b0110, 1'b0, 64'hFFFFFFFFFFFFFFFF, 1'b0, 1'b0);
        
        // Control signal forwarding
        $display("--- Control Signal Forwarding ---");
        MemRead = 1; MemtoReg = 1; MemWrite = 0; RegWrite = 1;
        Rd = 5'd25; ALUOp = 4'b0010; ALUSrc = 0; Branch = 0;
        #10;
        $display("MemRead: %b->%b %s | MemtoReg: %b->%b %s",
                 MemRead, MemReadOut, (MemRead===MemReadOut)?"PASS":"FAIL",
                 MemtoReg, MemtoRegOut, (MemtoReg===MemtoRegOut)?"PASS":"FAIL");
        $display("MemWrite: %b->%b %s | RegWrite: %b->%b %s",
                 MemWrite, MemWriteOut, (MemWrite===MemWriteOut)?"PASS":"FAIL",
                 RegWrite, RegWriteOut, (RegWrite===RegWriteOut)?"PASS":"FAIL");
        $display("Rd: %d->%d %s", Rd, RdOut, (Rd===RdOut)?"PASS":"FAIL");
        
        #10;
        $display("Execute testbench completed");
        $finish;
    end
    
    initial begin
        $dumpfile("execute_tb.vcd");
        $dumpvars(0, execute_tb);
    end

endmodule