module register_file (
    input wire clk,
    input wire reset,
    input wire [4:0] read_reg1,
    input wire [4:0] read_reg2,
    input wire [4:0] write_reg,
    input wire [63:0] write_data,
    input wire reg_write,
    output wire [63:0] read_data1,
    output wire [63:0] read_data2
);

    reg [63:0] registers [0:31];
    
    // Read with internal forwarding (if writing to same register being read)
    assign read_data1 = (read_reg1 == 5'b0) ? 64'b0 :
                       (reg_write && (write_reg == read_reg1) && (write_reg != 5'b0)) ? write_data :
                       registers[read_reg1];
                       
    assign read_data2 = (read_reg2 == 5'b0) ? 64'b0 :
                       (reg_write && (write_reg == read_reg2) && (write_reg != 5'b0)) ? write_data :
                       registers[read_reg2];
    
    // Synchronous write
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end
        else if (reg_write && write_reg != 5'b0) begin
            registers[write_reg] <= write_data;
        end
    end

endmodule