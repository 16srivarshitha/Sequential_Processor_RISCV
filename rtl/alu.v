module alu (
    input wire [63:0] input1,
    input wire [63:0] input2,
    input wire [3:0] alu_control,
    output reg [63:0] result,
    output wire zero
);

    // ALU operations
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SLT  = 4'b0111;
    localparam ALU_NOR  = 4'b1100;
    
    always @(*) begin
        case (alu_control)
            ALU_AND:  result = input1 & input2;
            ALU_OR:   result = input1 | input2;
            ALU_ADD:  result = input1 + input2;
            ALU_SUB:  result = input1 - input2;
            ALU_SLT:  result = ($signed(input1) < $signed(input2)) ? 64'b1 : 64'b0;
            ALU_NOR:  result = ~(input1 | input2);
            default:  result = 64'b0;
        endcase
    end
    
    assign zero = (result == 64'b0);

endmodule