// Testbench for single-cycle RISC-V processor
`timescale 1ns/1ps

module single_cycle_processor_tb;
    // Clock and reset signals
    reg clk;
    reg reset;
    
    // Instantiate the processor module
    single_cycle_processor dut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end
    
    // Task to display processor state
    task display_processor_state;
        input integer cycle_count;
        begin
            $display("--- Cycle %0d ---", cycle_count);
            $display("PC: 0x%h", dut.pc_current);
            $display("Instruction: 0x%h", dut.instruction);
            
            // Decode stage signals
            $display("\nDecode Stage:");
            $display("  ReadData1: 0x%h, ReadData2: 0x%h", dut.read_data1, dut.read_data2);
            $display("  ImmExt: 0x%h", dut.imm_ext);
            $display("  Control Signals:");
            $display("    RegWrite: %b, ALUSrc: %b, ALUOp: %b", 
                     dut.reg_write, dut.alu_src, dut.alu_op);
            $display("    Branch: %b, MemRead: %b, MemWrite: %b, MemtoReg: %b", 
                     dut.branch, dut.mem_read, dut.mem_write, dut.mem_to_reg);
            
            // Execute stage signals
            $display("\nExecute Stage:");
            $display("  ALU Result: 0x%h", dut.alu_result);
            $display("  Zero: %b, Branch Taken: %b", dut.zero, dut.branch_taken);
            $display("  Branch Target: 0x%h", dut.branch_target_addr);
            
            // Memory stage signals
            $display("\nMemory Stage:");
            $display("  ALU Result: 0x%h", dut.alu_result_mem);
            $display("  Memory Read Data: 0x%h", dut.read_data_mem);
            
            // Writeback stage signals
            $display("\nWriteback Stage:");
            $display("  Write Register: %0d", dut.write_reg);
            $display("  Write Data: 0x%h", dut.write_data_reg);
            $display("  RegWrite: %b", dut.reg_write_wb);
            
            // Display selected register values
            $display("\nRegister File State:");
            $display("  x0 (zero): 0x%h", dut.id_stage.registers[0]);
            $display("  x5: 0x%h", dut.id_stage.registers[5]);
            $display("  x6: 0x%h", dut.id_stage.registers[6]);
            $display("  x14: 0x%h", dut.id_stage.registers[14]);
            $display("  x16: 0x%h", dut.id_stage.registers[16]);
            $display("  x17: 0x%h", dut.id_stage.registers[17]);
            $display("  x18: 0x%h", dut.id_stage.registers[18]);
            $display("  x20: 0x%h", dut.id_stage.registers[20]);
            $display("  x21: 0x%h", dut.id_stage.registers[21]);
            
            // Display selected memory values
            $display("\nData Memory State:");
            $display("  Mem[32] (0x100): 0x%h", dut.mem_stage.memory[32]);
            $display("  Mem[64] (0x200): 0x%h", dut.mem_stage.memory[64]);
            
            $display("\n");
        end
    endtask
    
    // Task to initialize registers
    task initialize_registers;
        begin
            // Initialize key registers with test values
            dut.id_stage.registers[5] = 64'h0000000000000005;  // x5 = 5
            dut.id_stage.registers[6] = 64'h0000000000000006;  // x6 = 6
            dut.id_stage.registers[14] = 64'h0000000000000100; // x14 = 0x100
            dut.id_stage.registers[16] = 64'h0000000000000200; // x16 = 0x200
            dut.id_stage.registers[17] = 64'h0000000000000001; // x17 = 1
            dut.id_stage.registers[18] = 64'h0000000000000001; // x18 = 1 (same as x17 for branch test)
        end
    endtask
    
    // Test sequence
    initial begin
        // Initialize waveform dump
        $dumpfile("single_cycle_processor_tb.vcd");
        $dumpvars(0, single_cycle_processor_tb);
        
        // Initialize signals and apply reset
        $display("Starting test for single-cycle RISC-V processor");
        reset = 1;
        #20;
        reset = 0;
        
        // Initialize registers with test values
        initialize_registers();
        
        // Display initial state
        $display("==== INITIAL STATE ====");
        display_processor_state(0);
        
        // Run for 4 instructions + 2 extra cycles (6 cycles total)
        repeat(6) begin
            @(posedge clk);
            #1; // Small delay after clock edge to let signals settle
            display_processor_state($time/10);
        end
        
        // Verify final state
        $display("==== FINAL STATE VERIFICATION ====");
        
        // Check if x20 has loaded value from memory
        if (dut.id_stage.registers[20] === 64'h1234567890ABCDEF)
            $display("PASS: Register x20 correctly loaded from memory");
        else
            $display("FAIL: Register x20 = %h, expected 0x1234567890ABCDEF", dut.id_stage.registers[20]);
            
        // Check if x21 has the sum of x5 and x6
        if (dut.id_stage.registers[21] === 64'h000000000000000B) // 5 + 6 = 11 (0xB)
            $display("PASS: Register x21 correctly contains sum of x5 and x6");
        else
            $display("FAIL: Register x21 = %h, expected 0x000000000000000B", dut.id_stage.registers[21]);
            
        // Check if memory at address 0x200 has the value from x21
        if (dut.mem_stage.memory[64] === 64'h000000000000000B) // Memory address 0x200 / 8 = 64
            $display("PASS: Memory at 0x200 correctly stored value from x21");
        else
            $display("FAIL: Memory[0x200] = %h, expected 0x000000000000000B", dut.mem_stage.memory[64]);
            
        // Check if branch was taken (PC should jump ahead if x17 == x18)
        if (dut.pc_current === 64'h0000000000000010) // PC should be 16 after branch
            $display("PASS: Branch was correctly taken when x17 == x18");
        else
            $display("FAIL: PC = %h, expected 0x0000000000000010", dut.pc_current);
        
        $display("==== Test Complete ====");
        $finish;
    end
endmodule