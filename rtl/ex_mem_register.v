module ex_mem_register (
    input wire clk,
    input wire reset,
    
    // Inputs from EX stage
    input wire [63:0] alu_result_in,
    input wire [63:0] reg_data2_in,
    input wire [4:0] rd_in,
    input wire zero_in,
    
    // Control signals
    input wire RegWrite_in,
    input wire MemtoReg_in,
    input wire MemRead_in,
    input wire MemWrite_in,
    
    // Outputs to MEM stage
    output reg [63:0] alu_result_out,
    output reg [63:0] reg_data2_out,
    output reg [4:0] rd_out,
    output reg zero_out,
    
    // Control outputs
    output reg RegWrite_out,
    output reg MemtoReg_out,
    output reg MemRead_out,
    output reg MemWrite_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_out <= 64'b0;
            reg_data2_out <= 64'b0;
            rd_out <= 5'b0;
            zero_out <= 1'b0;
            
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 1'b0;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
        end
        else begin
            alu_result_out <= alu_result_in;
            reg_data2_out <= reg_data2_in;
            rd_out <= rd_in;
            zero_out <= zero_in;
            
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
        end
    end

endmodule