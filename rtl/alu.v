`timescale 1ns/1ps
// 32-bit ALU implementing the RV32I integer operations.
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output reg  [31:0] y,
    output wire        zero
);
    localparam ADD = 4'd0, SUB = 4'd1, SLL = 4'd2, SLT = 4'd3, SLTU = 4'd4,
               XOR = 4'd5, SRL = 4'd6, SRA = 4'd7, OR  = 4'd8, AND  = 4'd9;

    always @* begin
        case (op)
            ADD:     y = a + b;
            SUB:     y = a - b;
            SLL:     y = a << b[4:0];
            SLT:     y = {31'b0, ($signed(a) < $signed(b))};
            SLTU:    y = {31'b0, (a < b)};
            XOR:     y = a ^ b;
            SRL:     y = a >> b[4:0];
            SRA:     y = $signed(a) >>> b[4:0];
            OR:      y = a | b;
            AND:     y = a & b;
            default: y = 32'b0;
        endcase
    end

    assign zero = (y == 32'b0);
endmodule
