module fsm_controller (
    input wire clk,
    input wire reset,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire zero,
    
    // Control outputs
    output reg PCWrite,
    output reg PCWriteCond,
    output reg IorD,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg IRWrite,
    output reg [1:0] PCSource,
    output reg [1:0] ALUOp,
    output reg [1:0] ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg RegWrite,
    output reg RegDst
);

    // State encoding
    localparam FETCH        = 4'd0;
    localparam DECODE       = 4'd1;
    localparam MEMADR       = 4'd2;
    localparam MEMREAD      = 4'd3;
    localparam MEMWB        = 4'd4;
    localparam MEMWRITE     = 4'd5;
    localparam EXECUTE      = 4'd6;
    localparam ALUWRITEBACK = 4'd7;
    localparam BRANCH       = 4'd8;
    
    // Opcode definitions
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    
    reg [3:0] state, next_state;
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            FETCH: 
                next_state = DECODE;
            
            DECODE: begin
                case (opcode)
                    OP_RTYPE:  next_state = EXECUTE;
                    OP_LOAD:   next_state = MEMADR;
                    OP_STORE:  next_state = MEMADR;
                    OP_BRANCH: next_state = BRANCH;
                    default:   next_state = FETCH;
                endcase
            end
            
            MEMADR: begin
                case (opcode)
                    OP_LOAD:  next_state = MEMREAD;
                    OP_STORE: next_state = MEMWRITE;
                    default:  next_state = FETCH;
                endcase
            end
            
            MEMREAD:
                next_state = MEMWB;
            
            MEMWB:
                next_state = FETCH;
            
            MEMWRITE:
                next_state = FETCH;
            
            EXECUTE:
                next_state = ALUWRITEBACK;
            
            ALUWRITEBACK:
                next_state = FETCH;
            
            BRANCH:
                next_state = FETCH;
            
            default:
                next_state = FETCH;
        endcase
    end
    
    // Control signal generation
    always @(*) begin
        // Default values
        PCWrite = 0;
        PCWriteCond = 0;
        IorD = 0;
        MemRead = 0;
        MemWrite = 0;
        MemtoReg = 0;
        IRWrite = 0;
        PCSource = 2'b00;
        ALUOp = 2'b00;
        ALUSrcA = 2'b00;
        ALUSrcB = 2'b00;
        RegWrite = 0;
        RegDst = 0;
        
        case (state)
            FETCH: begin
                MemRead = 1;
                IorD = 0;
                IRWrite = 1;
                ALUSrcA = 2'b00;
                ALUSrcB = 2'b01;
                ALUOp = 2'b00;
                PCSource = 2'b00;
                PCWrite = 1;
            end
            
            DECODE: begin
                ALUSrcA = 2'b00;
                ALUSrcB = 2'b11;
                ALUOp = 2'b00;
            end
            
            MEMADR: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b10;
                ALUOp = 2'b00;
            end
            
            MEMREAD: begin
                MemRead = 1;
                IorD = 1;
            end
            
            MEMWB: begin
                RegDst = 0;
                MemtoReg = 1;
                RegWrite = 1;
            end
            
            MEMWRITE: begin
                MemWrite = 1;
                IorD = 1;
            end
            
            EXECUTE: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                ALUOp = 2'b10;
            end
            
            ALUWRITEBACK: begin
                RegDst = 1;
                MemtoReg = 0;
                RegWrite = 1;
            end
            
            BRANCH: begin
                ALUSrcA = 2'b10;
                ALUSrcB = 2'b00;
                ALUOp = 2'b01;
                PCWriteCond = 1;
                PCSource = 2'b01;
            end
            
            default: begin
            end
        endcase
    end

endmodule