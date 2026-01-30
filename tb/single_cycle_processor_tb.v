`timescale 1ns/1ps

module single_cycle_processor_tb;
    reg clk, reset;
    
    single_cycle_processor dut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;
    
    task display_state;
        input integer cycle;
        begin
            $display("\n=== Cycle %0d ===", cycle);
            $display("PC=%h | Instr=%h", dut.pc_current, dut.instruction);
            
            $display("Decode: RD1=%h RD2=%h Imm=%h",
                     dut.read_data1, dut.read_data2, dut.imm_ext);
            $display("  Ctrl: RW=%b AS=%b AOP=%b BR=%b MR=%b MW=%b M2R=%b",
                     dut.reg_write, dut.alu_src, dut.alu_op,
                     dut.branch, dut.mem_read, dut.mem_write, dut.mem_to_reg);
            
            $display("Execute: ALU=%h Z=%b BrTaken=%b",
                     dut.alu_result, dut.zero, dut.branch_taken);
            
            $display("Memory: ALU=%h MemData=%h",
                     dut.alu_result_mem, dut.read_data_mem);
            
            $display("Writeback: Reg=%d Data=%h WE=%b",
                     dut.write_reg, dut.write_data_reg, dut.reg_write_wb);
            
            $display("Registers: x5=%h x6=%h x14=%h x16=%h x20=%h x21=%h",
                     dut.id_stage.registers[5], dut.id_stage.registers[6],
                     dut.id_stage.registers[14], dut.id_stage.registers[16],
                     dut.id_stage.registers[20], dut.id_stage.registers[21]);
            
            $display("Memory: [32]=%h [64]=%h",
                     dut.mem_stage.mem[32], dut.mem_stage.mem[64]);
        end
    endtask
    
    task init_test;
        begin
            dut.id_stage.registers[5] = 64'h5;
            dut.id_stage.registers[6] = 64'h6;
            dut.id_stage.registers[14] = 64'h100;
            dut.id_stage.registers[16] = 64'h200;
            dut.id_stage.registers[17] = 64'h1;
            dut.id_stage.registers[18] = 64'h1;
            dut.id_stage.registers[20] = 64'h0;
            dut.id_stage.registers[21] = 64'h0;
            
            // Instructions
            dut.if_stage.instr_mem[0] = 32'h00073A03;  // ld x20, 0(x14)
            dut.if_stage.instr_mem[1] = 32'h00530AB3;  // add x21, x6, x5
            dut.if_stage.instr_mem[2] = 32'h01583023;  // sd x21, 0(x16)
            dut.if_stage.instr_mem[3] = 32'h01288863;  // beq x17, x18, 16
            dut.if_stage.instr_mem[4] = 32'h00000013;  // nop
            
            // Memory data
            dut.mem_stage.mem[32] = 64'h1234567890ABCDEF;
            dut.mem_stage.mem[64] = 64'h0;
        end
    endtask
    
    integer cycle_count;
    integer pass_count;
    integer fail_count;
    
    initial begin
        $dumpfile("single_cycle_processor_tb.vcd");
        $dumpvars(0, single_cycle_processor_tb);
        
        $display("Starting single-cycle RISC-V processor test");
        pass_count = 0;
        fail_count = 0;
        
        // Reset sequence
        reset = 1;
        #20;
        init_test();
        #10;
        reset = 0;
        
        // Cycle 1: LD instruction
        @(posedge clk);
        #1;
        cycle_count = 1;
        display_state(cycle_count);
        
        // Cycle 2: ADD instruction - verify LOAD completed
        @(posedge clk);
        #1;
        cycle_count = 2;
        display_state(cycle_count);
        $display("\n--- Check after LOAD ---");
        if (dut.id_stage.registers[20] === 64'h1234567890ABCDEF) begin
            $display("PASS: x20 loaded from memory");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: x20=%h (expected 0x1234567890ABCDEF)", dut.id_stage.registers[20]);
            fail_count = fail_count + 1;
        end
        
        // Cycle 3: SD instruction - verify ADD completed
        @(posedge clk);
        #1;
        cycle_count = 3;
        display_state(cycle_count);
        $display("\n--- Check after ADD ---");
        if (dut.id_stage.registers[21] === 64'hB) begin
            $display("PASS: x21 = x5 + x6 = 0x%h", dut.id_stage.registers[21]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: x21=%h (expected 0xB)", dut.id_stage.registers[21]);
            fail_count = fail_count + 1;
        end
        
        // Cycle 4: BEQ instruction - verify STORE completed
        @(posedge clk);
        #1;
        cycle_count = 4;
        display_state(cycle_count);
        $display("\n--- Check after STORE ---");
        if (dut.mem_stage.mem[64] === 64'hB) begin
            $display("PASS: Memory[0x200] stored x21 = 0x%h", dut.mem_stage.mem[64]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Mem[64]=%h (expected 0xB)", dut.mem_stage.mem[64]);
            fail_count = fail_count + 1;
        end
        
        @(posedge clk);
        #1;
        cycle_count = 5;
        display_state(cycle_count);
        $display("\n--- Check after BRANCH ---");
        if (dut.pc_current === 64'h1C) begin
            $display("PASS: Branch taken, PC jumped to 0x%h", dut.pc_current);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: PC=%h (expected 0x1C after branch)", dut.pc_current);
            fail_count = fail_count + 1;
        end
        
        $display("\n=== TEST SUMMARY ===");
        $display("Total Tests: %0d", pass_count + fail_count);
        $display("PASSED: %0d", pass_count);
        $display("FAILED: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***");
            $finish(0);
        end else begin
            $display("\n*** SOME TESTS FAILED ***");
            $finish(1);
        end
    end

endmodule