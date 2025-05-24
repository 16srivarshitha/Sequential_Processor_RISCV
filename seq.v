// Single-Cycle RISC-V Processor Implementation
`timescale 1ns/1ps
`include "fetch.v"
`include "decode.v"
`include "execute.v"
`include "memory.v"
`include "writeback.v"

module single_cycle_processor (
    input wire clk,             // System clock
    input wire reset            // Active high reset
);
    // Internal signals for connecting modules
    
    // Instruction Fetch outputs
    wire [31:0] instruction;
    wire [63:0] pc_current;
    wire [63:0] pc_next;
    
    // Branch signals
    wire branch_taken;
    wire [63:0] branch_target_addr;
    
    // Decode outputs
    wire [63:0] read_data1, read_data2, imm_ext;
    wire [4:0] rd;
    wire branch, mem_read, mem_to_reg, mem_write, alu_src, reg_dst, reg_write;
    wire [3:0] alu_op;
    
    // Execute outputs
    wire [63:0] alu_result, write_data_mem;
    wire zero;
    wire [4:0] rd_ex;
    wire mem_read_ex, mem_to_reg_ex, mem_write_ex, reg_write_ex;
    
    // Memory outputs
    wire [63:0] read_data_mem, alu_result_mem;
    wire [4:0] rd_mem;
    wire mem_to_reg_mem, reg_write_mem;
    
    // Writeback outputs
    wire [63:0] write_data_reg;
    wire [4:0] write_reg;
    wire reg_write_wb;
    
    // Calculate branch target address
    assign branch_target_addr = pc_current + imm_ext;
    
    // Instruction Fetch module
    instruction_fetch if_stage (
        .clk(clk),
        .rst_n(~reset),        // Convert active high to active low
        .stall(1'b0),          // No stall in single-cycle implementation
        .branch_taken(branch_taken),
        .branch_target_addr(branch_target_addr),
        .instruction(instruction),
        .pc_current(pc_current),
        .pc_next(pc_next)
    );
    
    // Decode module
    decode id_stage (
        .clk(clk),
        .reset(reset),
        .Instr(instruction),
        .ExtRegWrite(reg_write_wb),
        .RegWrite(reg_write),
        .WriteReg(write_reg),
        .WriteData(write_data_reg),
        .ReadData1(read_data1),
        .ReadData2(read_data2),
        .ImmExt(imm_ext),
        .Rd(rd),
        .Branch(branch),
        .MemRead(mem_read),
        .MemtoReg(mem_to_reg),
        .ALUOp(alu_op),
        .MemWrite(mem_write),
        .ALUSrc(alu_src),
        .RegDst(reg_dst)
    );
    
    // Execute module
    execute ex_stage (
        .ReadData1(read_data1),
        .ReadData2(read_data2),
        .ImmExt(imm_ext),
        .Rd(rd),
        .ALUOp(alu_op),
        .ALUSrc(alu_src),
        .Branch(branch),
        .MemRead(mem_read),
        .MemtoReg(mem_to_reg),
        .MemWrite(mem_write),
        .RegWrite(reg_write),
        .ALUResult(alu_result),
        .Zero(zero),
        .BranchTaken(branch_taken),
        .WriteData(write_data_mem),
        .RdOut(rd_ex),
        .MemReadOut(mem_read_ex),
        .MemtoRegOut(mem_to_reg_ex),
        .MemWriteOut(mem_write_ex),
        .RegWriteOut(reg_write_ex)
    );
    
    // Memory module
    memory mem_stage (
        .clk(clk),
        .reset(reset),
        .ALUResult(alu_result),
        .WriteData(write_data_mem),
        .Rd(rd_ex),
        .Zero(zero),
        .BranchTaken(branch_taken),
        .MemRead(mem_read_ex),
        .MemWrite(mem_write_ex),
        .MemtoReg(mem_to_reg_ex),
        .RegWrite(reg_write_ex),
        .ReadData(read_data_mem),
        .ALUResultOut(alu_result_mem),
        .RdOut(rd_mem),
        .BranchTakenOut(), // Not used in single-cycle
        .MemtoRegOut(mem_to_reg_mem),
        .RegWriteOut(reg_write_mem)
    );
    
    // Writeback module
    writeback wb_stage (
        .ReadData(read_data_mem),
        .ALUResult(alu_result_mem),
        .Rd(rd_mem),
        .MemtoReg(mem_to_reg_mem),
        .RegWrite(reg_write_mem),
        .WriteData(write_data_reg),
        .WriteReg(write_reg),
        .RegWriteOut(reg_write_wb)
    );
    
    // Instruction memory initialization
    initial begin
        // Initialize instruction memory in the fetch stage
        // This is a simple test program:
        // - Load from memory address 0x100 (from x14) to x20
        // - Add x6 and x5 into x21
        // - Store x21 to memory address 0x200 (from x16)
        // - Branch to PC+16 if x17 == x18
        
        // ld x20, 0(x14)   - Load from memory
        if_stage.instr_mem[0] = 32'h00070503;  // I-type format
        
        // add x21, x6, x5  - Add registers
        if_stage.instr_mem[1] = 32'h005302b3;  // R-type format
        
        // sd x21, 0(x16)   - Store to memory
        if_stage.instr_mem[2] = 32'h00b80023;  // S-type format
        
        // beq x17, x18, 16 - Branch if equal
        if_stage.instr_mem[3] = 32'h03208063;  // B-type format
        
        
        // Pre-initialize some value in the memory for load instruction
        mem_stage.memory[32] = 64'h1234567890ABCDEF;  // Value at address 0x100 (x14 = 0x100, address 0x100/8 = 32)
    end
    
endmodule