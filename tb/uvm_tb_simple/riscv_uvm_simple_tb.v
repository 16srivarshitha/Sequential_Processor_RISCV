`timescale 1ns/1ps


module driver(
    input clk,
    output reg reset
);
    
    task run_test(
        input [31:0] instruction,
        input [255:0] test_name 
    );
        
        $display("\n[DRIVER] Running test: %0s", test_name);
        
        reset = 1;
        #20;
        
        riscv_uvm_tb.dut.if_stage.instr_mem[0] = instruction;
        
        #10;
        reset = 0;
        
        repeat(2) @(posedge clk);
        #1;
        
    endtask
endmodule


module monitor(input clk);
    always @(posedge clk) begin
        if (!riscv_uvm_tb.reset) begin
            $display("[MONITOR] PC=0x%0h, Instr=0x%08h", 
                     riscv_uvm_tb.dut.pc_current, 
                     riscv_uvm_tb.dut.instruction);
        end
    end
endmodule


// SCOREBOARD: Checks results

module scoreboard();
    
    integer pass_count = 0;
    integer fail_count = 0;
    
    task check_reg(input [4:0] addr, input [63:0] expected, input [255:0] msg);
        reg [63:0] actual;
        actual = riscv_uvm_tb.dut.id_stage.registers[addr];
        
        if (actual === expected) begin
            $display("[SCOREBOARD] PASS - %0s: x%0d = 0x%0h", msg, addr, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[SCOREBOARD] FAIL - %0s: x%0d = 0x%0h (expected 0x%0h)", 
                     msg, addr, actual, expected);
            fail_count = fail_count + 1;
        end
    endtask
    
    task check_mem(input [9:0] addr, input [63:0] expected, input [255:0] msg);
        reg [63:0] actual;
        actual = riscv_uvm_tb.dut.mem_stage.mem[addr];
        
        if (actual === expected) begin
            $display("[SCOREBOARD] PASS - %0s: mem[%0d] = 0x%0h", msg, addr, actual);
            pass_count = pass_count + 1;
        end else begin
            $display("[SCOREBOARD] FAIL - %0s: mem[%0d] = 0x%0h (expected 0x%0h)", 
                     msg, addr, actual, expected);
            fail_count = fail_count + 1;
        end
    endtask
    
    task print_results();
        $display("\n==========================================");
        $display("           TEST RESULTS");
        $display("==========================================");
        $display("Total: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        if (fail_count > 0) $display("Failed: %0d", fail_count);
        $display("==========================================");
    endtask
endmodule


// TOP MODULE

module riscv_uvm_tb;
    
    reg clk;
    wire reset;
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT Instantiation
    single_cycle_processor dut (
        .clk(clk),
        .reset(reset)
    );
    
    // Instantiate Verification Components
    driver     drv(.clk(clk), .reset(reset));
    monitor    mon(.clk(clk));
    scoreboard sb();
    
    // Test Sequences
    initial begin
        integer i;
        
        $dumpfile("dump.vcd");
        $dumpvars(0, riscv_uvm_tb);
        
        $display("\n==========================================");
        $display("    RISC-V Processor Simple Testbench");
        $display("==========================================\n");
        
        
        // TEST 1: ADD x6, x5, x6
        // Setup inputs: x5=5, x6=6
        riscv_uvm_tb.dut.id_stage.registers[5] = 64'h5;
        riscv_uvm_tb.dut.id_stage.registers[6] = 64'h6;
        
        drv.run_test(
            32'h00628333, // add x6, x5, x6
            "ADD x6, x5, x6"
        );
        sb.check_reg(6, 64'hB, "ADD result"); // Expect 11 (0xB)
        
        
        // TEST 2: LOAD x20, 0(x14)
        // Setup: x14=0x100, Mem[0x20]=0xDEADBEEF
        riscv_uvm_tb.dut.id_stage.registers[14] = 64'h100; // Base addr
        riscv_uvm_tb.dut.mem_stage.mem[32] = 64'hDEADBEEFDEADBEEF; // 0x100 >> 3 = 32
        
        drv.run_test(
            32'h00073A03, // ld x20, 0(x14) 
            "LOAD x20, 0(x14)"
        );
        
        sb.check_reg(20, 64'hDEADBEEFDEADBEEF, "LOAD result");
        
        
        #50;
        sb.print_results();
        $finish;
    end
    
endmodule