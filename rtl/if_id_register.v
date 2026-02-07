module if_id_register (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    
    // Inputs from IF stage
    input wire [63:0] pc_in,
    input wire [31:0] instruction_in,
    
    // Outputs to ID stage
    output reg [63:0] pc_out,
    output reg [31:0] instruction_out
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            pc_out <= 64'b0;
            instruction_out <= 32'b0;
        end
        else if (!stall) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
        end
        // If stall, maintain current values
    end

endmodule