`timescale 1ns/1ps

module writeback_tb;
    reg [63:0] ReadData, ALUResult;
    reg [4:0] Rd;
    reg MemtoReg, RegWrite;
    
    wire [63:0] WriteData;
    wire [4:0] WriteReg;
    wire RegWriteOut;
    
    // Instantiate DUT
    writeback dut (
        .ReadData(ReadData), .ALUResult(ALUResult), .Rd(Rd),
        .MemtoReg(MemtoReg), .RegWrite(RegWrite),
        .WriteData(WriteData), .WriteReg(WriteReg),
        .RegWriteOut(RegWriteOut)
    );
    
    // Check task
    task check_wb;
        input [127:0] name;
        input [63:0] exp_data;
        input [4:0] exp_reg;
        input exp_write;
        reg pass;
        begin
            pass = (WriteData === exp_data) && (WriteReg === exp_reg) &&
                   (RegWriteOut === exp_write);
            $display("--- %0s ---", name);
            $display("Data=%h(%h) | Reg=%d(%d) | Write=%b(%b) | %s",
                     WriteData, exp_data, WriteReg, exp_reg,
                     RegWriteOut, exp_write, pass ? "PASS" : "FAIL");
        end
    endtask
    
    // Test sequence
    initial begin
        {ReadData, ALUResult, Rd} = {64'd0, 64'd0, 5'd0};
        {MemtoReg, RegWrite} = 2'b0;
        #10;
        
        // Select ALU result
        ReadData = 64'hAAAAAAAAAAAAAAAA;
        ALUResult = 64'hBBBBBBBBBBBBBBBB;
        Rd = 5'd7; MemtoReg = 0; RegWrite = 1;
        #10 check_wb("Select ALU", 64'hBBBBBBBBBBBBBBBB, 5'd7, 1'b1);
        
        // Select memory data
        ReadData = 64'hDEADBEEFDEADBEEF;
        ALUResult = 64'h1234567890ABCDEF;
        Rd = 5'd12; MemtoReg = 1; RegWrite = 1;
        #10 check_wb("Select Memory", 64'hDEADBEEFDEADBEEF, 5'd12, 1'b1);
        
        // RegWrite disabled
        Rd = 5'd31; MemtoReg = 0; RegWrite = 0;
        ALUResult = 64'hFEDCBA9876543210;
        #10 check_wb("RegWrite=0", 64'hFEDCBA9876543210, 5'd31, 1'b0);
        
        // Zero register
        Rd = 5'd0; MemtoReg = 0; RegWrite = 1;
        ALUResult = 64'hEEEEEEEEEEEEEEEE;
        #10 check_wb("x0 register", 64'hEEEEEEEEEEEEEEEE, 5'd0, 1'b1);
        
        // All ones
        ReadData = 64'hFFFFFFFFFFFFFFFF;
        Rd = 5'b11111; MemtoReg = 1; RegWrite = 1;
        #10 check_wb("All ones", 64'hFFFFFFFFFFFFFFFF, 5'b11111, 1'b1);
        
        #10;
        $display("Writeback testbench completed");
        $finish;
    end
    
    initial begin
        $dumpfile("writeback_tb.vcd");
        $dumpvars(0, writeback_tb);
    end

endmodule