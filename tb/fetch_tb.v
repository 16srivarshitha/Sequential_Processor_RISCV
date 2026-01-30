`timescale 1ns/1ps

module instruction_fetch_tb;
    reg clk, rst_n, stall, branch_taken;
    reg [63:0] branch_target_addr;
    wire [31:0] instruction;
    wire [63:0] pc_current;
    
    instruction_fetch dut (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .branch_taken(branch_taken),
        .branch_target_addr(branch_target_addr),
        .instruction(instruction),
        .pc_current(pc_current)
    );
    
    // Clock: 100MHz (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;
    
    initial begin
        dut.instr_mem[0] = 32'h00000013;  // NOP
        dut.instr_mem[1] = 32'h00500113;  // addi x2, x0, 5
        dut.instr_mem[2] = 32'h00310233;  // add x4, x2, x3
        dut.instr_mem[3] = 32'hFE000AE3;  // beq x0, x0, -12
        dut.instr_mem[4] = 32'h00628293;  // addi x5, x5, 6
        dut.instr_mem[10] = 32'h00700393; // addi x7, x0, 7
        dut.instr_mem[11] = 32'h00700393;
    end
    
    initial begin
        rst_n = 0;
        stall = 0;
        branch_taken = 0;
        branch_target_addr = 64'h0;
        
        #15 rst_n = 1;
        
        #30;
        
        // Test stall
        stall = 1;
        #20;
        stall = 0;
        #10;
        
        // Test branch
        branch_taken = 1;
        branch_target_addr = 64'h28; // Jump to address 0x28
        #10;
        branch_taken = 0;
        #20;
        
        // Test reset
        rst_n = 0;
        #10;
        rst_n = 1;
        #30;
        
        $display("Fetch testbench completed");
        $finish;
    end
    
    initial begin
        $monitor("T=%0t | RST=%b | STALL=%b | BR=%b | PC=%h | INSTR=%h",
                 $time, rst_n, stall, branch_taken, pc_current, instruction);
    end
    
    initial begin
        $dumpfile("instruction_fetch_tb.vcd");
        $dumpvars(0, instruction_fetch_tb);
    end

endmodule