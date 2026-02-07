module data_memory #(
    parameter MEM_SIZE = 8192
)(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [12:0] address,
    input wire [63:0] write_data,
    output reg [63:0] read_data
);

    reg [7:0] memory [0:MEM_SIZE-1];
    
    // Read operation
    always @(*) begin
        if (mem_read) begin
            read_data = {memory[address + 7],
                        memory[address + 6],
                        memory[address + 5],
                        memory[address + 4],
                        memory[address + 3],
                        memory[address + 2],
                        memory[address + 1],
                        memory[address]};
        end else begin
            read_data = 64'b0;
        end
    end
    
    // Write operation
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address]     <= write_data[7:0];
            memory[address + 1] <= write_data[15:8];
            memory[address + 2] <= write_data[23:16];
            memory[address + 3] <= write_data[31:24];
            memory[address + 4] <= write_data[39:32];
            memory[address + 5] <= write_data[47:40];
            memory[address + 6] <= write_data[55:48];
            memory[address + 7] <= write_data[63:56];
        end
    end
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            memory[i] = 8'b0;
        end
        
        // Load from file if provided
        if ($test$plusargs("DATA_MEM_FILE")) begin
            $readmemh("data_memory.hex", memory);
        end
    end

endmodule