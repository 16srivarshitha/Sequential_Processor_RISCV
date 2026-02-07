module pipelined_processor (
    input wire clk,
    input wire reset
);

    // ========== IF Stage Signals ==========
    wire [63:0] pc;
    wire [63:0] pc_plus_4;
    wire [63:0] pc_next;
    wire [31:0] if_instruction;
    wire pc_src;
    wire [63:0] branch_target;
    
    // ========== IF/ID Pipeline Register Signals ==========
    wire [63:0] id_pc;
    wire [31:0] id_instruction;
    wire if_id_stall;
    wire if_id_flush;
    
    // ========== ID Stage Signals ==========
    wire [6:0] id_opcode;
    wire [4:0] id_rd, id_rs1, id_rs2;
    wire [2:0] id_funct3;
    wire [6:0] id_funct7;
    wire [63:0] id_reg_data1, id_reg_data2;
    wire [63:0] id_imm;
    wire id_Branch, id_MemRead, id_MemtoReg, id_MemWrite, id_ALUSrc, id_RegWrite;
    wire [1:0] id_ALUOp;
    
    // ========== ID/EX Pipeline Register Signals ==========
    wire [63:0] ex_pc;
    wire [63:0] ex_reg_data1, ex_reg_data2;
    wire [63:0] ex_imm;
    wire [4:0] ex_rs1, ex_rs2, ex_rd;
    wire [2:0] ex_funct3;
    wire [6:0] ex_funct7;
    wire ex_RegWrite, ex_MemtoReg, ex_MemRead, ex_MemWrite;
    wire [1:0] ex_ALUOp;
    wire ex_ALUSrc;
    wire id_ex_flush;
    
    // ========== EX Stage Signals ==========
    wire [63:0] ex_alu_input1, ex_alu_input2;
    wire [63:0] ex_alu_result;
    wire ex_zero;
    wire [3:0] ex_alu_control;
    wire [1:0] forwardA, forwardB;
    wire [63:0] ex_forward_data1, ex_forward_data2;
    
    // ========== EX/MEM Pipeline Register Signals ==========
    wire [63:0] mem_alu_result;
    wire [63:0] mem_reg_data2;
    wire [4:0] mem_rd;
    wire mem_zero;
    wire mem_RegWrite, mem_MemtoReg, mem_MemRead, mem_MemWrite;
    
    // ========== MEM Stage Signals ==========
    wire [63:0] mem_read_data;
    
    // ========== MEM/WB Pipeline Register Signals ==========
    wire [63:0] wb_mem_data;
    wire [63:0] wb_alu_result;
    wire [4:0] wb_rd;
    wire wb_RegWrite, wb_MemtoReg;
    
    // ========== WB Stage Signals ==========
    wire [63:0] wb_write_data;
    
    // ========== Hazard Detection Signals ==========
    wire stall;
    
    // ========== PC Register ==========
    reg [63:0] PC;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 64'b0;
        else if (!stall)
            PC <= pc_next;
    end
    
    assign pc = PC;
    assign pc_plus_4 = pc + 4;
    
    // ========== IF Stage ==========
    // Instruction memory (simplified - using existing memory modules)
    instruction_memory #(.MEM_SIZE(4096)) imem (
        .address(pc[11:0]),
        .instruction(if_instruction)
    );
    
    // Branch target calculation and PC selection
    assign branch_target = id_pc + id_imm;
    assign pc_src = id_Branch && ex_zero;  // Branch taken
    assign pc_next = pc_src ? branch_target : pc_plus_4;
    
    // ========== IF/ID Pipeline Register ==========
    if_id_register if_id (
        .clk(clk),
        .reset(reset),
        .stall(if_id_stall),
        .flush(if_id_flush),
        .pc_in(pc),
        .instruction_in(if_instruction),
        .pc_out(id_pc),
        .instruction_out(id_instruction)
    );
    
    // ========== ID Stage ==========
    // Instruction decode
    assign id_opcode = id_instruction[6:0];
    assign id_rd = id_instruction[11:7];
    assign id_funct3 = id_instruction[14:12];
    assign id_rs1 = id_instruction[19:15];
    assign id_rs2 = id_instruction[24:20];
    assign id_funct7 = id_instruction[31:25];
    
    // Immediate generation
    wire [63:0] imm_I, imm_S, imm_B;
    assign imm_I = {{52{id_instruction[31]}}, id_instruction[31:20]};
    assign imm_S = {{52{id_instruction[31]}}, id_instruction[31:25], id_instruction[11:7]};
    assign imm_B = {{51{id_instruction[31]}}, id_instruction[31], id_instruction[7], 
                    id_instruction[30:25], id_instruction[11:8], 1'b0};
    
    assign id_imm = (id_opcode == 7'b0000011) ? imm_I :  // Load
                    (id_opcode == 7'b0100011) ? imm_S :  // Store
                    (id_opcode == 7'b1100011) ? imm_B :  // Branch
                    (id_opcode == 7'b0010011) ? imm_I :  // I-type
                    imm_I;
    
    // Control unit
    pipeline_control control (
        .opcode(id_opcode),
        .Branch(id_Branch),
        .MemRead(id_MemRead),
        .MemtoReg(id_MemtoReg),
        .ALUOp(id_ALUOp),
        .MemWrite(id_MemWrite),
        .ALUSrc(id_ALUSrc),
        .RegWrite(id_RegWrite)
    );
    
    // Register file
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .read_reg1(id_rs1),
        .read_reg2(id_rs2),
        .write_reg(wb_rd),
        .write_data(wb_write_data),
        .reg_write(wb_RegWrite),
        .read_data1(id_reg_data1),
        .read_data2(id_reg_data2)
    );
    
    // ========== ID/EX Pipeline Register ==========
    id_ex_register id_ex (
        .clk(clk),
        .reset(reset),
        .flush(id_ex_flush),
        .pc_in(id_pc),
        .reg_data1_in(id_reg_data1),
        .reg_data2_in(id_reg_data2),
        .imm_in(id_imm),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .funct3_in(id_funct3),
        .funct7_in(id_funct7),
        .RegWrite_in(id_RegWrite),
        .MemtoReg_in(id_MemtoReg),
        .MemRead_in(id_MemRead),
        .MemWrite_in(id_MemWrite),
        .ALUOp_in(id_ALUOp),
        .ALUSrc_in(id_ALUSrc),
        .pc_out(ex_pc),
        .reg_data1_out(ex_reg_data1),
        .reg_data2_out(ex_reg_data2),
        .imm_out(ex_imm),
        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd),
        .funct3_out(ex_funct3),
        .funct7_out(ex_funct7),
        .RegWrite_out(ex_RegWrite),
        .MemtoReg_out(ex_MemtoReg),
        .MemRead_out(ex_MemRead),
        .MemWrite_out(ex_MemWrite),
        .ALUOp_out(ex_ALUOp),
        .ALUSrc_out(ex_ALUSrc)
    );
    
    // ========== EX Stage ==========
    // Forwarding unit
    forwarding_unit forward (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .mem_rd(mem_rd),
        .mem_RegWrite(mem_RegWrite),
        .wb_rd(wb_rd),
        .wb_RegWrite(wb_RegWrite),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    // Forwarding muxes
    assign ex_forward_data1 = (forwardA == 2'b00) ? ex_reg_data1 :
                              (forwardA == 2'b01) ? mem_alu_result :
                              (forwardA == 2'b10) ? wb_write_data :
                              ex_reg_data1;
    
    assign ex_forward_data2 = (forwardB == 2'b00) ? ex_reg_data2 :
                              (forwardB == 2'b01) ? mem_alu_result :
                              (forwardB == 2'b10) ? wb_write_data :
                              ex_reg_data2;
    
    // ALU input selection
    assign ex_alu_input1 = ex_forward_data1;
    assign ex_alu_input2 = ex_ALUSrc ? ex_imm : ex_forward_data2;
    
    // ALU control
    alu_control alu_ctrl (
        .alu_op(ex_ALUOp),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .alu_control(ex_alu_control)
    );
    
    // ALU
    alu alu_unit (
        .input1(ex_alu_input1),
        .input2(ex_alu_input2),
        .alu_control(ex_alu_control),
        .result(ex_alu_result),
        .zero(ex_zero)
    );
    
    // ========== EX/MEM Pipeline Register ==========
    ex_mem_register ex_mem (
        .clk(clk),
        .reset(reset),
        .alu_result_in(ex_alu_result),
        .reg_data2_in(ex_forward_data2),
        .rd_in(ex_rd),
        .zero_in(ex_zero),
        .RegWrite_in(ex_RegWrite),
        .MemtoReg_in(ex_MemtoReg),
        .MemRead_in(ex_MemRead),
        .MemWrite_in(ex_MemWrite),
        .alu_result_out(mem_alu_result),
        .reg_data2_out(mem_reg_data2),
        .rd_out(mem_rd),
        .zero_out(mem_zero),
        .RegWrite_out(mem_RegWrite),
        .MemtoReg_out(mem_MemtoReg),
        .MemRead_out(mem_MemRead),
        .MemWrite_out(mem_MemWrite)
    );
    
    // ========== MEM Stage ==========
    // Data memory
    data_memory #(.MEM_SIZE(8192)) dmem (
        .clk(clk),
        .mem_read(mem_MemRead),
        .mem_write(mem_MemWrite),
        .address(mem_alu_result[12:0]),
        .write_data(mem_reg_data2),
        .read_data(mem_read_data)
    );
    
    // ========== MEM/WB Pipeline Register ==========
    mem_wb_register mem_wb (
        .clk(clk),
        .reset(reset),
        .mem_data_in(mem_read_data),
        .alu_result_in(mem_alu_result),
        .rd_in(mem_rd),
        .RegWrite_in(mem_RegWrite),
        .MemtoReg_in(mem_MemtoReg),
        .mem_data_out(wb_mem_data),
        .alu_result_out(wb_alu_result),
        .rd_out(wb_rd),
        .RegWrite_out(wb_RegWrite),
        .MemtoReg_out(wb_MemtoReg)
    );
    
    // ========== WB Stage ==========
    assign wb_write_data = wb_MemtoReg ? wb_mem_data : wb_alu_result;
    
    // ========== Hazard Detection Unit ==========
    hazard_detection_unit hazard (
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .ex_rd(ex_rd),
        .ex_MemRead(ex_MemRead),
        .mem_rd(mem_rd),
        .mem_MemRead(mem_MemRead),
        .id_branch(id_Branch),
        .ex_branch(1'b0),  // Branch handled in ID stage
        .stall(stall),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );
    
    assign if_id_stall = stall;

endmodule