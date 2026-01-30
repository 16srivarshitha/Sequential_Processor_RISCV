`timescale 1ns/1ps

module decode_tb;
    reg clk, reset;
    reg [31:0] Instr;
    reg ExtRegWrite;
    reg [4:0] WriteReg;
    reg [63:0] WriteData;
    
    wire RegWrite;
    wire [63:0] ReadData1, ReadData2, ImmExt;
    wire [4:0] Rd;
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegDst;
    wire [3:0] ALUOp;
    
    // Test instructions
    localparam ADD_INSTR = 32'h003100B3;  // add x1, x2, x3
    localparam SUB_INSTR = 32'h40628233;  // sub x4, x5, x6
    localparam AND_INSTR = 32'h00947433;  // and x8, x8, x9
    localparam OR_INSTR  = 32'h00C5E533;  // or x10, x11, x12
    localparam LD_INSTR  = 32'h00873683;  // ld x13, 8(x14)
    localparam SD_INSTR  = 32'h00F83823;  // sd x15, 16(x16)
    localparam BEQ_INSTR = 32'h01280863;  // beq x16, x18, 16
    
    // Instantiate DUT
    decode dut (
        .clk(clk), .reset(reset), .Instr(Instr),
        .ExtRegWrite(ExtRegWrite), .RegWrite(RegWrite),
        .WriteReg(WriteReg), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2),
        .ImmExt(ImmExt), .Rd(Rd),
        .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg),
        .ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc),
        .RegDst(RegDst)
    );
    
    // Clock: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Initialize register file with test values
    initial begin
        #1; // Small delay to ensure registers exist
        dut.registers[0] = 64'h0;
        dut.registers[2] = 64'h2;
        dut.registers[3] = 64'h3;
        dut.registers[5] = 64'h5;
        dut.registers[6] = 64'h6;
        dut.registers[8] = 64'h8;
        dut.registers[9] = 64'h9;
        dut.registers[11] = 64'hB;
        dut.registers[12] = 64'hC;
        dut.registers[14] = 64'h100;
        dut.registers[15] = 64'hF;
        dut.registers[16] = 64'h200;
        dut.registers[17] = 64'h17;
        dut.registers[18] = 64'h17;
        dut.registers[20] = 64'h0;
    end
    
    // Display task
    task check_decode;
        input [127:0] name;
        input [6:0] exp_op;
        input [4:0] exp_rs1, exp_rs2, exp_rd;
        input [3:0] exp_alu;
        input exp_alusrc;
        reg pass;
        begin
            pass = (Instr[6:0] === exp_op) && 
                   (Instr[19:15] === exp_rs1) &&
                   (Instr[24:20] === exp_rs2) &&
                   (Rd === exp_rd) &&
                   (ALUOp === exp_alu) &&
                   (ALUSrc === exp_alusrc);
            
            $display("--- %0s ---", name);
            $display("Instr=%h | Op=%b(%b) | rs1=%d(%d) | rs2=%d(%d) | Rd=%d(%d)",
                     Instr, Instr[6:0], exp_op, Instr[19:15], exp_rs1,
                     Instr[24:20], exp_rs2, Rd, exp_rd);
            $display("ALUOp=%b(%b) | ALUSrc=%b(%b) | %s",
                     ALUOp, exp_alu, ALUSrc, exp_alusrc, pass ? "PASS" : "FAIL");
            $display("ReadData1=%h | ReadData2=%h | ImmExt=%h",
                     ReadData1, ReadData2, ImmExt);
            $display("");
        end
    endtask
    
    initial begin
        reset = 1;
        Instr = 32'h0;
        ExtRegWrite = 0;
        WriteReg = 5'b0;
        WriteData = 64'h0;
        
        #10 reset = 0;
        #10;
        
        // Test R-type instructions
        Instr = ADD_INSTR;
        #10 check_decode("ADD x1,x2,x3", 7'b0110011, 5'd2, 5'd3, 5'd1, 4'b0010, 1'b0);
        
        Instr = SUB_INSTR;
        #10 check_decode("SUB x4,x5,x6", 7'b0110011, 5'd5, 5'd6, 5'd4, 4'b0110, 1'b0);
        
        Instr = AND_INSTR;
        #10 check_decode("AND x8,x8,x9", 7'b0110011, 5'd8, 5'd9, 5'd8, 4'b0111, 1'b0);
        
        Instr = OR_INSTR;
        #10 check_decode("OR x10,x11,x12", 7'b0110011, 5'd11, 5'd12, 5'd10, 4'b0001, 1'b0);
        
        // Test I-type load
        Instr = LD_INSTR;
        #10 check_decode("LD x13,8(x14)", 7'b0000011, 5'd14, 5'd8, 5'd13, 4'b0000, 1'b1);
        
        // Test S-type store
        Instr = SD_INSTR;
        #10 check_decode("SD x15,16(x16)", 7'b0100011, 5'd16, 5'd15, 5'd0, 4'b0000, 1'b1);
        
        // Test B-type branch
        Instr = BEQ_INSTR;
        #10 check_decode("BEQ x16,x18,16", 7'b1100011, 5'd16, 5'd18, 5'd0, 4'b0110, 1'b0);
        
        // Test register write
        $display("--- Register Write Test ---");
        $display("Initial x20 = %h", dut.registers[20]);
        
        ExtRegWrite = 1;
        WriteReg = 5'd20;
        WriteData = 64'hDEADBEEF_DEADBEEF;
        #10;
        $display("After write x20 = %h (expected %h) %s",
                 dut.registers[20], 64'hDEADBEEF_DEADBEEF,
                 (dut.registers[20] === 64'hDEADBEEF_DEADBEEF) ? "PASS" : "FAIL");
        
        // Test x0 protection
        WriteReg = 5'd0;
        WriteData = 64'hFFFFFFFF_FFFFFFFF;
        #10;
        $display("After write x0 = %h (should be 0) %s",
                 dut.registers[0],
                 (dut.registers[0] === 64'h0) ? "PASS" : "FAIL");
        
        #10;
        $display("Decode testbench completed");
        $finish;
    end
    
    initial begin
        $dumpfile("decode_tb.vcd");
        $dumpvars(0, decode_tb);
    end

endmodule