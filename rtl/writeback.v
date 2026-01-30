module writeback (
    input wire [63:0] ReadData,
    input wire [63:0] ALUResult,
    input wire [4:0] Rd,
    input wire MemtoReg,
    input wire RegWrite,
    
    output wire [63:0] WriteData,
    output wire [4:0] WriteReg,
    output wire RegWriteOut
);

    // Writeback data selection
    assign WriteData = MemtoReg ? ReadData : ALUResult;
    assign WriteReg = Rd;
    assign RegWriteOut = RegWrite;

endmodule