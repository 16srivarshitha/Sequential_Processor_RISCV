module pipelined_processor_tb;

    reg clk;
    reg reset;
    
    integer cycle_count;
    integer stall_count;
    integer forward_count;
    integer i;
    
    pipelined_processor dut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Load test program into instruction memory
    initial begin
        $dumpfile("pipelined_processor.vcd");
        $dumpvars(0, pipelined_processor_tb);
        
        // Wait for memory to be initialized
        #1;
        
        $display("Loading test program into instruction memory...");
        
        // TEST PROGRAM:
        // 0:  ADDI x1, x0, 10      # x1 = 10
        // 4:  ADDI x2, x0, 20      # x2 = 20
        // 8:  ADD  x3, x1, x2      # x3 = 30 (tests EX hazard - forward from MEM)
        // 12: SUB  x4, x3, x1      # x4 = 20 (tests EX hazard - forward from WB)
        // 16: AND  x5, x3, x2      # x5 = x3 & x2
        // 20: OR   x6, x1, x2      # x6 = x1 | x2
        // 24: SD   x1, 0(x0)       # Store x1 to mem[0]
        // 28: SD   x2, 8(x0)       # Store x2 to mem[8]
        // 32: LD   x7, 0(x0)       # Load from mem[0] to x7
        // 36: ADD  x8, x7, x1      # x8 = x7 + x1 (tests load-use hazard)
        
        // Instruction 0: ADDI x1, x0, 10
        // Format: imm[11:0] | rs1 | 000 | rd | 0010011
        // imm=10(0x00A), rs1=0, rd=1
        dut.imem.memory[0]  = 8'h93;  // 0010011 + rd[0]=1
        dut.imem.memory[1]  = 8'h00;  // funct3=000 + rd[4:1]=0000
        dut.imem.memory[2]  = 8'hA0;  // rs1[4:0]=00000 + imm[4:0]=01010
        dut.imem.memory[3]  = 8'h00;  // imm[11:5]=0000000
        
        // Instruction 1: ADDI x2, x0, 20
        // imm=20(0x014), rs1=0, rd=2
        dut.imem.memory[4]  = 8'h13;  // 0010011 + rd[0]=0
        dut.imem.memory[5]  = 8'h01;  // funct3=000 + rd[4:1]=0001
        dut.imem.memory[6]  = 8'h40;  // rs1=00000 + imm[4:0]=10100
        dut.imem.memory[7]  = 8'h01;  // imm[11:5]=0000001
        
        // Instruction 2: ADD x3, x1, x2
        // Format: 0000000 | rs2 | rs1 | 000 | rd | 0110011
        // Binary: 0000000 00010 00001 000 00011 0110011
        // Hex: 0x002081B3
        // rs1=1, rs2=2, rd=3
        dut.imem.memory[8]  = 8'hB3;  // [7:0]   = 10110011
        dut.imem.memory[9]  = 8'h81;  // [15:8]  = 10000001 
        dut.imem.memory[10] = 8'h20;  // [23:16] = 00100000
        dut.imem.memory[11] = 8'h00;  // [31:24] = 00000000
        
        // Instruction 3: SUB x4, x3, x1
        // Hex: 0x40118233
        dut.imem.memory[12] = 8'h33;
        dut.imem.memory[13] = 8'h82;  
        dut.imem.memory[14] = 8'h11;
        dut.imem.memory[15] = 8'h40;
        
        // Instruction 4: AND x5, x3, x2
        // Hex: 0x0021F2B3
        dut.imem.memory[16] = 8'hB3;
        dut.imem.memory[17] = 8'hF2;  
        dut.imem.memory[18] = 8'h21;
        dut.imem.memory[19] = 8'h00;
        
        // Instruction 5: OR x6, x1, x2
        // Hex: 0x0020E333
        dut.imem.memory[20] = 8'h33;
        dut.imem.memory[21] = 8'hE3;  
        dut.imem.memory[22] = 8'h20;
        dut.imem.memory[23] = 8'h00;
        
        // Instruction 6: SD x1, 0(x0)
        // Format: imm[11:5] | rs2 | rs1 | 011 | imm[4:0] | 0100011
        // rs1=0, rs2=1, imm=0
        dut.imem.memory[24] = 8'h23;  // 0100011 + imm[0]=0
        dut.imem.memory[25] = 8'h30;  // funct3=011 + imm[4:1]=0000
        dut.imem.memory[26] = 8'h10;  // rs1=00000 + rs2[2:0]=001
        dut.imem.memory[27] = 8'h00;  // imm[11:5]=0000000 + rs2[4:3]=00
        
        // Instruction 7: SD x2, 8(x0)
        // rs1=0, rs2=2, imm=8
        dut.imem.memory[28] = 8'h23;  // 0100011 + imm[0]=0
        dut.imem.memory[29] = 8'h34;  // funct3=011 + imm[4:1]=0100
        dut.imem.memory[30] = 8'h20;  // rs1=00000 + rs2[2:0]=010
        dut.imem.memory[31] = 8'h00;  // imm[11:5]=0000000 + rs2[4:3]=00
        
        // Instruction 8: LD x7, 0(x0)
        // Format: imm[11:0] | rs1 | 011 | rd | 0000011
        // rs1=0, rd=7, imm=0
        dut.imem.memory[32] = 8'h83;  // 0000011 + rd[0]=1
        dut.imem.memory[33] = 8'h33;  // funct3=011 + rd[4:1]=0011
        dut.imem.memory[34] = 8'h00;  // rs1=00000 + imm[4:0]=00000
        dut.imem.memory[35] = 8'h00;  // imm[11:5]=0000000
        
        // Instruction 9: ADD x8, x7, x1
        // Hex: 0x00138433
        dut.imem.memory[36] = 8'h33;
        dut.imem.memory[37] = 8'h84;  
        dut.imem.memory[38] = 8'h13;
        dut.imem.memory[39] = 8'h00;
        
        $display("Program loaded successfully!");
        $display("");
        $display("Expected Results:");
        $display("  x1  = 10");
        $display("  x2  = 20");
        $display("  x3  = 30  (10 + 20)");
        $display("  x4  = 20  (30 - 10)");
        $display("  x5  = 20  (30 & 20)");
        $display("  x6  = 30  (10 | 20)");
        $display("  x7  = 10  (loaded from memory)");
        $display("  x8  = 20  (10 + 10)");
        $display("  mem[0] = 10");
        $display("  mem[8] = 20");
        $display("");
        
        // Initialize counters
        cycle_count = 0;
        stall_count = 0;
        forward_count = 0;
        
        // Reset
        reset = 1;
        #20;
        reset = 0;
        
        // Run simulation
        #300;
        
        // Display results
        $display("\n========== SIMULATION RESULTS ==========");
        $display("\nRegister Values:");
        $display("  x0  = %0d (expected: 0)", dut.reg_file.registers[0]);
        $display("  x1  = %0d (expected: 10)", dut.reg_file.registers[1]);
        $display("  x2  = %0d (expected: 20)", dut.reg_file.registers[2]);
        $display("  x3  = %0d (expected: 30)", dut.reg_file.registers[3]);
        $display("  x4  = %0d (expected: 20)", dut.reg_file.registers[4]);
        $display("  x5  = %0d (expected: 20)", dut.reg_file.registers[5]);
        $display("  x6  = %0d (expected: 30)", dut.reg_file.registers[6]);
        $display("  x7  = %0d (expected: 10)", dut.reg_file.registers[7]);
        $display("  x8  = %0d (expected: 20)", dut.reg_file.registers[8]);
        
        $display("\nMemory Contents:");
        $display("  mem[0]  = %0d (expected: 10)", 
                {dut.dmem.memory[7], dut.dmem.memory[6], dut.dmem.memory[5], dut.dmem.memory[4],
                 dut.dmem.memory[3], dut.dmem.memory[2], dut.dmem.memory[1], dut.dmem.memory[0]});
        $display("  mem[8]  = %0d (expected: 20)",
                {dut.dmem.memory[15], dut.dmem.memory[14], dut.dmem.memory[13], dut.dmem.memory[12],
                 dut.dmem.memory[11], dut.dmem.memory[10], dut.dmem.memory[9], dut.dmem.memory[8]});
        
        $display("\nPerformance Metrics:");
        $display("  Total cycles: %0d", cycle_count);
        $display("  Stalls: %0d", stall_count);
        $display("  Forwards: %0d", forward_count);
        $display("  CPI: %.2f", $itor(cycle_count) / 10.0);
        
        // Check correctness
        $display("\n========== TEST RESULTS ==========");
        if (dut.reg_file.registers[1] == 10 &&
            dut.reg_file.registers[2] == 20 &&
            dut.reg_file.registers[3] == 30 &&
            dut.reg_file.registers[4] == 20 &&
            dut.reg_file.registers[5] == 20 &&
            dut.reg_file.registers[6] == 30 &&
            dut.reg_file.registers[7] == 10 &&
            dut.reg_file.registers[8] == 20) begin
            $display(" ALL TESTS PASSED!");
        end else begin
            $display(" TESTS FAILED!");
        end
        
        $finish;
    end
    
    // Cycle counter
    always @(posedge clk) begin
        if (!reset)
            cycle_count = cycle_count + 1;
    end
    
    // Monitor stalls
    always @(posedge clk) begin
        if (!reset && dut.stall) begin
            stall_count = stall_count + 1;
            $display("  >>> STALL at cycle %0d", cycle_count);
        end
    end
    
    // Monitor forwarding with values
    always @(posedge clk) begin
        if (!reset) begin
            if (dut.forwardA != 2'b00 || dut.forwardB != 2'b00) begin
                forward_count = forward_count + 1;
                $display("  >>> FORWARD at cycle %0d:", cycle_count);
                if (dut.forwardA == 2'b01)
                    $display("      ForwardA=MEM: rs1=x%0d, MEM_rd=x%0d, value=%0d", 
                            dut.ex_rs1, dut.mem_rd, dut.mem_alu_result);
                else if (dut.forwardA == 2'b10)
                    $display("      ForwardA=WB:  rs1=x%0d, WB_rd=x%0d, value=%0d",
                            dut.ex_rs1, dut.wb_rd, dut.wb_write_data);
                            
                if (dut.forwardB == 2'b01)
                    $display("      ForwardB=MEM: rs2=x%0d, MEM_rd=x%0d, value=%0d",
                            dut.ex_rs2, dut.mem_rd, dut.mem_alu_result);
                else if (dut.forwardB == 2'b10)
                    $display("      ForwardB=WB:  rs2=x%0d, WB_rd=x%0d, value=%0d",
                            dut.ex_rs2, dut.wb_rd, dut.wb_write_data);
            end
        end
    end
    
    // Debug monitor (optional - comment out for less verbose output)
    always @(posedge clk) begin
        if (!reset && cycle_count < 20) begin
            $display("Cycle %0d: PC=%0d IF=%h ID=%h EX_rd=%0d MEM_rd=%0d WB_rd=%0d",
                     cycle_count, dut.pc, dut.if_instruction, dut.id_instruction,
                     dut.ex_rd, dut.mem_rd, dut.wb_rd);
        end
    end
    
    // Timeout
    initial begin
        #2000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule