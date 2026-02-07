module mem_wb_register (
    input wire clk,
    input wire reset,
    
    // Inputs from MEM stage
    input wire [63:0] mem_data_in,
    input wire [63:0] alu_result_in,
    input wire [4:0] rd_in,
    
    // Control signals
    input wire RegWrite_in,
    input wire MemtoReg_in,
    
    // Outputs to WB stage
    output reg [63:0] mem_data_out,
    output reg [63:0] alu_result_out,
    output reg [4:0] rd_out,
    
    // Control outputs
    output reg RegWrite_out,
    output reg MemtoReg_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_data_out <= 64'b0;
            alu_result_out <= 64'b0;
            rd_out <= 5'b0;
            
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 1'b0;
        end
        else begin
            mem_data_out <= mem_data_in;
            alu_result_out <= alu_result_in;
            rd_out <= rd_in;
            
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
        end
    end

endmodule