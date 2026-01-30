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
    
    // Initialize
    task init_test;
        begin
            dut.id_stage.registers[5] = 64'h5;
            dut.id_stage.registers[6] = 64'h6;
            dut.id_stage.registers[14] = 64'h100;
            dut.id_stage.registers[16] = 64'h200;
            dut.id_stage.registers[17] = 64'h1;
            dut.id_stage.registers[18] = 64'h1;
            dut.id_stage.registers[20] = 64'h0;  // Clear destination
            dut.id_stage.registers[21] = 64'h0;  // Clear destination
            
            // Inst
            dut.if_stage.instr_mem[0] = 32'h00073A03;  // ld x20, 0(x14)
            dut.if_stage.instr_mem[1] = 32'h00530AB3;  // add x21, x6, x5
            dut.if_stage.instr_mem[2] = 32'h01583023;  // sd x21, 0(x16)
            dut.if_stage.instr_mem[3] = 32'h01288863;  // beq x17, x18, 16
            dut.if_stage.instr_mem[4] = 32'h00000013;  // nop (shouldn't execute)
            
            // Memory data
            dut.mem_stage.mem[32] = 64'h1234567890ABCDEF;
            dut.mem_stage.mem[64] = 64'h0;  // Clear store location
        end
    endtask
    
    integer cycle_count;
    
    initial begin
        $dumpfile("single_cycle_processor_tb.vcd");
        $dumpvars(0, single_cycle_processor_tb);
        
        $display("Starting single-cycle RISC-V processor test");
        
        reset = 1;
        #10;
        
        // Initialize while in reset
        init_test();
        
        #10 reset = 0;
        
        @(posedge clk);
        #1;  
        
        cycle_count = 1;
        display_state(cycle_count);
        
        repeat(6) begin
            @(posedge clk);
            #1;
            cycle_count = cycle_count + 1;
            display_state(cycle_count);
        end
        
        $display("\n=== VERIFICATION ===");
        
        if (dut.id_stage.registers[20] === 64'h1234567890ABCDEF)
            $display("PASS: x20 loaded from memory");
        else
            $display("FAIL: x20=%h (expected 0x1234567890ABCDEF)",
                    dut.id_stage.registers[20]);
        
        if (dut.id_stage.registers[21] === 64'hB)
            $display("PASS: x21 = x5 + x6");
        else
            $display("FAIL: x21=%h (expected 0xB)",
                    dut.id_stage.registers[21]);
        
        if (dut.mem_stage.mem[64] === 64'hB)
            $display("PASS: Memory[0x200] stored x21");
        else
            $display("FAIL: Mem[64]=%h (expected 0xB)",
                    dut.mem_stage.mem[64]);
        
        if (dut.pc_current === 64'h1C)
            $display("PASS: Branch taken correctly");
        else
            $display("FAIL: PC=%h (expected 0x1C)",
                    dut.pc_current);
        
        $display("\n=== TEST COMPLETE ===");
        $finish;
    end

endmodule