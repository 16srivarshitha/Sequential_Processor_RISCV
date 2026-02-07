module hazard_detection_unit (
    // ID stage instruction registers
    input wire [4:0] id_rs1,
    input wire [4:0] id_rs2,
    
    // EX stage instruction
    input wire [4:0] ex_rd,
    input wire ex_MemRead,
    
    // MEM stage instruction
    input wire [4:0] mem_rd,
    input wire mem_MemRead,
    
    // Branch detection
    input wire id_branch,
    input wire ex_branch,
    
    // Hazard outputs
    output reg stall,
    output reg if_id_flush,
    output reg id_ex_flush
);

    always @(*) begin
        // Default: no stall or flush
        stall = 0;
        if_id_flush = 0;
        id_ex_flush = 0;
        
        // Load-use hazard detection
        // If EX stage has a load and its destination matches ID stage source
        if (ex_MemRead && ((ex_rd == id_rs1) || (ex_rd == id_rs2)) && (ex_rd != 5'b0)) begin
            stall = 1;
            id_ex_flush = 1;  // Insert bubble in EX stage
        end
        
        // Branch hazard - flush IF/ID if branch in ID or EX stage
        if (id_branch || ex_branch) begin
            if_id_flush = 1;
            id_ex_flush = 1;
        end
    end

endmodule