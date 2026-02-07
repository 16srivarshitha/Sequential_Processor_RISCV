module forwarding_unit (
    // EX stage operands
    input wire [4:0] ex_rs1,
    input wire [4:0] ex_rs2,
    
    // MEM stage instruction
    input wire [4:0] mem_rd,
    input wire mem_RegWrite,
    
    // WB stage instruction
    input wire [4:0] wb_rd,
    input wire wb_RegWrite,
    
    // Forwarding control outputs
    output reg [1:0] forwardA,  // 00: no forward, 01: forward from MEM, 10: forward from WB
    output reg [1:0] forwardB
);

    always @(*) begin
        // Default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        // ForwardA (rs1)
        // Priority: MEM stage > WB stage
        if (mem_RegWrite && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
            forwardA = 2'b01;  // Forward from MEM stage (EX hazard)
        end
        else if (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
            forwardA = 2'b10;  // Forward from WB stage (MEM hazard)
        end
        
        // ForwardB (rs2)
        // Priority: MEM stage > WB stage
        if (mem_RegWrite && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
            forwardB = 2'b01;  // Forward from MEM stage (EX hazard)
        end
        else if (wb_RegWrite && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
            forwardB = 2'b10;  // Forward from WB stage (MEM hazard)
        end
    end

endmodule