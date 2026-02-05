module multi_cycle_processor (
    input wire clk,
    input wire reset
);

    // Internal wires
    wire [63:0] pc;
    wire [31:0] instruction;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rs1, rs2, rd;
    wire [63:0] imm_extended;
    
    // Register file signals
    wire [63:0] reg_data1, reg_data2;
    wire [63:0] write_data;
    wire RegWrite;
    
    // ALU signals
    wire [63:0] alu_input1, alu_input2;
    wire [63:0] alu_result;
    wire zero;
    wire [3:0] alu_control;
    
    // Control signals from FSM
    wire PCWrite, PCWriteCond;
    wire IorD;
    wire MemRead, MemWrite;
    wire MemtoReg;
    wire IRWrite;
    wire [1:0] PCSource;
    wire [1:0] ALUOp;
    wire [1:0] ALUSrcA, ALUSrcB;
    wire RegDst;
    
    // Internal register outputs
    wire [31:0] IR;
    wire [63:0] MDR;
    wire [63:0] A, B;
    wire [63:0] ALUOut;
    
    // Memory signals
    wire [31:0] mem_instruction;
    wire [63:0] mem_read_data;
    
    // PC register
    reg [63:0] PC;
    
    // PC update logic
    wire pc_enable;
    wire [63:0] pc_next;
    
    assign pc_enable = PCWrite || (PCWriteCond && zero);
    
    // PC source multiplexer
    assign pc_next = (PCSource == 2'b00) ? ALUOut :          // PC + 4 or ALU result
                     (PCSource == 2'b01) ? ALUOut :          // Branch target
                                           ALUOut;           // Default
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 64'b0;
        else if (pc_enable)
            PC <= pc_next;
    end
    
    assign pc = PC;
    
    // Instruction decode
    assign opcode = IR[6:0];
    assign rd     = IR[11:7];
    assign funct3 = IR[14:12];
    assign rs1    = IR[19:15];
    assign rs2    = IR[24:20];
    assign funct7 = IR[31:25];
    
    // Immediate extension
    wire [63:0] imm_I, imm_S, imm_B;
    
    assign imm_I = {{52{IR[31]}}, IR[31:20]};
    assign imm_S = {{52{IR[31]}}, IR[31:25], IR[11:7]};
    assign imm_B = {{51{IR[31]}}, IR[31], IR[7], IR[30:25], IR[11:8], 1'b0};
    
    // Select immediate based on instruction type
    assign imm_extended = (opcode == 7'b0000011) ? imm_I :  // Load
                         (opcode == 7'b0100011) ? imm_S :   // Store
                         (opcode == 7'b1100011) ? imm_B :   // Branch
                                                 imm_I;     // Default
    
    // FSM Controller
    fsm_controller fsm (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .zero(zero),
        .PCWrite(PCWrite),
        .PCWriteCond(PCWriteCond),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),
        .PCSource(PCSource),
        .ALUOp(ALUOp),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .RegWrite(RegWrite),
        .RegDst(RegDst)
    );
    
    // Internal Registers
    internal_registers int_regs (
        .clk(clk),
        .reset(reset),
        .IRWrite(IRWrite),
        .instruction_in(mem_instruction),
        .IR(IR),
        .mem_data_in(mem_read_data),
        .MDR(MDR),
        .reg_data1(reg_data1),
        .reg_data2(reg_data2),
        .A(A),
        .B(B),
        .alu_result(alu_result),
        .ALUOut(ALUOut)
    );
    
    // Unified Memory
    unified_memory #(
        .MEM_SIZE(12288)
    ) memory (
        .clk(clk),
        .reset(reset),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .IorD(IorD),
        .pc_addr(PC),
        .data_addr(ALUOut),
        .write_data(B),
        .instruction(mem_instruction),
        .read_data(mem_read_data)
    );
    
    // Register File
    wire [4:0] write_reg;
    assign write_reg = RegDst ? rd : rd;  // For now, always rd
    
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .read_reg1(rs1),
        .read_reg2(rs2),
        .write_reg(write_reg),
        .write_data(write_data),
        .reg_write(RegWrite),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );
    
    // Write data multiplexer
    assign write_data = MemtoReg ? MDR : ALUOut;
    
    // ALU input multiplexers
    assign alu_input1 = (ALUSrcA == 2'b00) ? PC :
                       (ALUSrcA == 2'b01) ? PC :
                       (ALUSrcA == 2'b10) ? A :
                                           64'b0;
    
    assign alu_input2 = (ALUSrcB == 2'b00) ? B :
                       (ALUSrcB == 2'b01) ? 64'd4 :
                       (ALUSrcB == 2'b10) ? imm_extended :
                       (ALUSrcB == 2'b11) ? imm_extended :
                                           64'b0;
    
    // ALU Control
    alu_control alu_ctrl (
        .alu_op(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );
    
    // ALU
    alu alu_unit (
        .input1(alu_input1),
        .input2(alu_input2),
        .alu_control(alu_control),
        .result(alu_result),
        .zero(zero)
    );

endmodule