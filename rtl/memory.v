module memory (
    input wire clk,
    input wire reset,
    input wire [63:0] ALUResult,
    input wire [63:0] WriteData,
    input wire [4:0] Rd,
    input wire Zero,
    input wire BranchTaken,
    input wire MemRead,
    input wire MemWrite,
    input wire MemtoReg,
    input wire RegWrite,
    output wire [63:0] ReadData,
    output wire [63:0] ALUResultOut,
    output wire [4:0] RdOut,
    output wire BranchTakenOut,
    output wire MemtoRegOut,
    output wire RegWriteOut
);

// Data memory: 1024 x 64-bit = 8KB
reg [63:0] mem [0:1023]/*verilator public*/;
reg [63:0] read_data;

// Memory address calculation (byte to word)
wire [9:0] mem_addr = ALUResult[12:3];

// Check if address is valid (< 8192 bytes = 1024 words * 8 bytes)
wire addr_valid = (ALUResult < 64'd8192);  

// Memory read (combinational)
always @(*) begin
    if (MemRead && addr_valid)
        read_data = mem[mem_addr];
    else
        read_data = 64'd0;
end

// Memory write (synchronous)
always @(posedge clk) begin
    if (!reset && MemWrite && addr_valid) begin
        mem[mem_addr] <= WriteData;
    end
end

assign ReadData = read_data;
assign ALUResultOut = ALUResult;
assign RdOut = Rd;
assign BranchTakenOut = BranchTaken;
assign MemtoRegOut = MemtoReg;
assign RegWriteOut = RegWrite;

endmodule