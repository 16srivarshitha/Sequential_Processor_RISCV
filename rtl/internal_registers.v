module internal_registers (
    input wire clk,
    input wire reset,
    
    // Instruction Register
    input wire IRWrite,
    input wire [31:0] instruction_in,
    output reg [31:0] IR,
    
    // Memory Data Register
    input wire [63:0] mem_data_in,
    output reg [63:0] MDR,
    
    // A and B registers (hold rs1 and rs2 values)
    input wire [63:0] reg_data1,
    input wire [63:0] reg_data2,
    output reg [63:0] A,
    output reg [63:0] B,
    
    // ALU Output register
    input wire [63:0] alu_result,
    output reg [63:0] ALUOut
);

    // Instruction Register - only updates when IRWrite is asserted
    always @(posedge clk or posedge reset) begin
        if (reset)
            IR <= 32'b0;
        else if (IRWrite)
            IR <= instruction_in;
    end
    
    // Memory Data Register - always captures memory output
    always @(posedge clk or posedge reset) begin
        if (reset)
            MDR <= 64'b0;
        else
            MDR <= mem_data_in;
    end
    
    // A register - captures rs1 value during decode
    always @(posedge clk or posedge reset) begin
        if (reset)
            A <= 64'b0;
        else
            A <= reg_data1;
    end
    
    // B register - captures rs2 value during decode
    always @(posedge clk or posedge reset) begin
        if (reset)
            B <= 64'b0;
        else
            B <= reg_data2;
    end
    
    // ALU Output register - captures ALU result
    always @(posedge clk or posedge reset) begin
        if (reset)
            ALUOut <= 64'b0;
        else
            ALUOut <= alu_result;
    end

endmodule