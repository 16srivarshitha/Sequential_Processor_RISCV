module id_ex_register (
    input wire clk,
    input wire reset,
    input wire flush,
    
    // Inputs from ID stage
    input wire [63:0] pc_in,
    input wire [63:0] reg_data1_in,
    input wire [63:0] reg_data2_in,
    input wire [63:0] imm_in,
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [4:0] rd_in,
    input wire [2:0] funct3_in,
    input wire [6:0] funct7_in,
    
    // Control signals
    input wire RegWrite_in,
    input wire MemtoReg_in,
    input wire MemRead_in,
    input wire MemWrite_in,
    input wire [1:0] ALUOp_in,
    input wire ALUSrc_in,
    
    // Outputs to EX stage
    output reg [63:0] pc_out,
    output reg [63:0] reg_data1_out,
    output reg [63:0] reg_data2_out,
    output reg [63:0] imm_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [2:0] funct3_out,
    output reg [6:0] funct7_out,
    
    // Control outputs
    output reg RegWrite_out,
    output reg MemtoReg_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg [1:0] ALUOp_out,
    output reg ALUSrc_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out <= 64'b0;
            reg_data1_out <= 64'b0;
            reg_data2_out <= 64'b0;
            imm_out <= 64'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            rd_out <= 5'b0;
            funct3_out <= 3'b0;
            funct7_out <= 7'b0;
            
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 1'b0;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
            ALUOp_out <= 2'b0;
            ALUSrc_out <= 1'b0;
        end
        else begin
            pc_out <= pc_in;
            reg_data1_out <= reg_data1_in;
            reg_data2_out <= reg_data2_in;
            imm_out <= imm_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            funct3_out <= funct3_in;
            funct7_out <= funct7_in;
            
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            ALUOp_out <= ALUOp_in;
            ALUSrc_out <= ALUSrc_in;
        end
    end

endmodule