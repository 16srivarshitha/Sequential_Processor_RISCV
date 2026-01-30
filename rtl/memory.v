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
    reg [63:0] mem [0:1023];
    reg [63:0] read_data;
    
    // Memory address calculation (byte to word)
    wire [9:0] mem_addr = ALUResult[12:3];
    wire addr_valid = (ALUResult[12:3] < 10'd1024);
    
    // Memory read (combinational)
    always @(*) begin
        if (MemRead && addr_valid)
            read_data = mem[mem_addr];
        else
            read_data = 64'd0;
    end
    
    // Memory write (synchronous)
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 1024; i = i + 1)
                mem[i] <= 64'd0;
        end 
        else if (MemWrite && addr_valid) begin
            mem[mem_addr] <= WriteData;
        end
    end
    
    // Outputs
    assign ReadData = read_data;
    assign ALUResultOut = ALUResult;
    assign RdOut = Rd;
    assign BranchTakenOut = BranchTaken;
    assign MemtoRegOut = MemtoReg;
    assign RegWriteOut = RegWrite;

endmodule