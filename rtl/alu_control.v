module alu_control (
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output reg [3:0] alu_control
);

    // ALU operations
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SLT  = 4'b0111;
    
    always @(*) begin
        case (alu_op)
            2'b00: begin
                // Load/Store - always ADD
                alu_control = ALU_ADD;
            end
            
            2'b01: begin
                // Branch - always SUB for comparison
                alu_control = ALU_SUB;
            end
            
            2'b10: begin
                // R-type or I-type - use funct3 and funct7
                case (funct3)
                    3'b000: begin
                        // ADD or SUB
                        if (funct7 == 7'b0100000)
                            alu_control = ALU_SUB;
                        else
                            alu_control = ALU_ADD;
                    end
                    3'b111: alu_control = ALU_AND;  // AND
                    3'b110: alu_control = ALU_OR;   // OR
                    3'b010: alu_control = ALU_SLT;  // SLT
                    default: alu_control = ALU_ADD;
                endcase
            end
            
            default: alu_control = ALU_ADD;
        endcase
    end

endmodule