// Single-Cycle RISC-V Processor Implementation
`timescale 1ns/1ps

module single_cycle_processor (
    input wire clk,
    input wire reset
);

    // Fetch stage outputs
    wire [31:0] instruction;
    wire [63:0] pc_current;
    
    // Decode stage outputs
    wire [63:0] read_data1, read_data2, imm_ext;
    wire [4:0] rd;
    wire branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    wire [3:0] alu_op;
    
    // Execute stage outputs
    wire [63:0] alu_result, write_data_mem;
    wire zero, branch_taken;
    wire [4:0] rd_ex;
    wire mem_read_ex, mem_to_reg_ex, mem_write_ex, reg_write_ex;
    
    // Memory stage outputs
    wire [63:0] read_data_mem, alu_result_mem;
    wire [4:0] rd_mem;
    wire mem_to_reg_mem, reg_write_mem;
    
    // Writeback stage outputs
    wire [63:0] write_data_reg;
    wire [4:0] write_reg;
    wire reg_write_wb;
    
    // Branch target calculation
    wire [63:0] branch_target_addr = (pc_current - 64'd4) + imm_ext;    
    // Instruction Fetch
    instruction_fetch if_stage (
        .clk(clk),
        .rst_n(~reset),
        .stall(1'b0),
        .branch_taken(branch_taken),
        .branch_target_addr(branch_target_addr),
        .instruction(instruction),
        .pc_current(pc_current)
    );
    
    // Decode
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
        .RegDst()  // Unused in single-cycle
    );
    
    // Execute
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
    
    // Memory
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
        .BranchTakenOut(),  // Unused
        .MemtoRegOut(mem_to_reg_mem),
        .RegWriteOut(reg_write_mem)
    );
    
    // Writeback
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

endmodule