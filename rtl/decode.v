module decode (
    input wire clk,
    input wire reset,
    input wire [31:0] Instr,
    input wire ExtRegWrite,
    output wire RegWrite,
    input wire [4:0] WriteReg,
    input wire [63:0] WriteData,
    output wire [63:0] ReadData1,
    output wire [63:0] ReadData2,
    output wire [63:0] ImmExt,
    output wire [4:0] Rd,
    output wire Branch,
    output wire MemRead,
    output wire MemtoReg,
    output wire [3:0] ALUOp,
    output wire MemWrite,
    output wire ALUSrc,
    output wire RegDst
);

    wire [6:0] opcode = Instr[6:0];
    wire [4:0] rd_addr = Instr[11:7];
    wire [2:0] funct3 = Instr[14:12];
    wire [4:0] rs1_addr = Instr[19:15];
    wire [4:0] rs2_addr = Instr[24:20];
    wire [6:0] funct7 = Instr[31:25];
    
    // Register file
    reg [63:0] registers [0:31]/*verilator public*/;
    
    // Register read (combinational with x0 hardwired to 0)
    assign ReadData1 = (rs1_addr == 5'd0) ? 64'd0 : registers[rs1_addr];
    assign ReadData2 = (rs2_addr == 5'd0) ? 64'd0 : registers[rs2_addr];
    
    // Register write (synchronous)
    always @(posedge clk) begin
        if (ExtRegWrite && (WriteReg != 5'd0))
            registers[WriteReg] <= WriteData;
    end
    
    // Immediate generation (combinational)
    reg [63:0] imm;
    always @(*) begin
        case (opcode)
            7'b0000011: // I-type (ld)
                imm = {{52{Instr[31]}}, Instr[31:20]};
            7'b0100011: // S-type (sd)
                imm = {{52{Instr[31]}}, Instr[31:25], Instr[11:7]};
            7'b1100011: // B-type (beq)
                imm = {{51{Instr[31]}}, Instr[31], Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            default:
                imm = 64'd0;
        endcase
    end
    assign ImmExt = imm;
    
    // Control signal generation
    reg branch, memRead, memtoReg, memWrite, aluSrc, regDst, regWriteInt;
    reg [3:0] aluOp;
    
    always @(*) begin
        // Defaults
        {branch, memRead, memtoReg, memWrite, aluSrc, regDst, regWriteInt} = 7'b0;
        aluOp = 4'b0000;
        
        case (opcode)
            7'b0110011: begin // R-type
                regDst = 1'b1;
                regWriteInt = 1'b1;
                case ({funct3, funct7[5]})
                    4'b0000: aluOp = 4'b0010; // add
                    4'b0001: aluOp = 4'b0110; // sub
                    4'b1110: aluOp = 4'b0111; // and
                    4'b1100: aluOp = 4'b0001; // or
                    default: aluOp = 4'b0000;
                endcase
            end
            
            7'b0000011: begin // ld (I-type load)
                regDst = 1'b1;
                aluSrc = 1'b1;
                memtoReg = 1'b1;
                regWriteInt = 1'b1;
                memRead = 1'b1;
            end
            
            7'b0100011: begin // sd (S-type store)
                aluSrc = 1'b1;
                memWrite = 1'b1;
            end
            
            7'b1100011: begin // beq (B-type branch)
                branch = 1'b1;
                aluOp = 4'b0110;
            end
        endcase
    end
    
    assign Branch = branch;
    assign MemRead = memRead;
    assign MemtoReg = memtoReg;
    assign ALUOp = aluOp;
    assign MemWrite = memWrite;
    assign ALUSrc = aluSrc;
    assign RegDst = regDst;
    assign RegWrite = regWriteInt;
    
    // Rd output (0 for S-type and B-type)
    assign Rd = (opcode == 7'b0100011 || opcode == 7'b1100011) ? 5'd0 : rd_addr;

endmodule