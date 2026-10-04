`timescale 1ns/1ps
// Self-checking ALU testbench: directed corner cases + 5000 random vectors.
// The reference model uses loops/bit tricks so it is independent of the RTL's operators.
module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  op;
    wire [31:0] y;
    wire        zero;
    alu dut (.a(a), .b(b), .op(op), .y(y), .zero(zero));

    integer errors = 0, checks = 0, i, k;
    reg [31:0] exp;

    function [31:0] ref_model(input [31:0] x, input [31:0] z, input [3:0] o);
        reg [31:0] t; integer s;
        begin
            s = z[4:0]; t = x;
            case (o)
                4'd0: ref_model = x + z;
                4'd1: ref_model = x + (~z + 1);                       // two's complement subtract
                4'd2: begin repeat (s) t = {t[30:0], 1'b0};          ref_model = t; end
                4'd3: ref_model = (x[31] != z[31]) ? {31'b0, x[31]} : {31'b0, (x < z)};
                4'd4: ref_model = {31'b0, (x < z)};
                4'd5: ref_model = (x | z) & ~(x & z);
                4'd6: begin repeat (s) t = {1'b0, t[31:1]};          ref_model = t; end
                4'd7: begin repeat (s) t = {t[31], t[31:1]};         ref_model = t; end
                4'd8: ref_model = x | z;
                4'd9: ref_model = x & z;
                default: ref_model = 32'b0;
            endcase
        end
    endfunction

    task check(input [31:0] x, input [31:0] z, input [3:0] o);
        begin
            a = x; b = z; op = o; #1;
            exp = ref_model(x, z, o);
            checks = checks + 1;
            if (y !== exp || zero !== (exp == 0)) begin
                errors = errors + 1;
                $display("FAIL op=%0d a=%h b=%h got=%h exp=%h zero=%b", o, x, z, y, exp, zero);
            end
        end
    endtask

    reg [31:0] corners [0:7];
    initial begin
        $dumpfile("alu.vcd"); $dumpvars(0, tb_alu);
        corners[0] = 32'h0;        corners[1] = 32'h1;        corners[2] = 32'hFFFFFFFF;
        corners[3] = 32'h80000000; corners[4] = 32'h7FFFFFFF; corners[5] = 32'h0000FFFF;
        corners[6] = 32'hAAAAAAAA; corners[7] = 32'h55555555;
        for (k = 0; k < 10; k = k + 1)                              // every op x every corner pair
            for (i = 0; i < 64; i = i + 1)
                check(corners[i / 8], corners[i % 8], k[3:0]);
        for (i = 0; i < 5000; i = i + 1)                            // seeded -> reproducible
            check($random, $random, $urandom % 10);
        check(32'h12345678, 32'h0, 4'd15);                          // undefined opcode -> 0
        // Spec checks that matter: SLT signed vs SLTU unsigned, SRA keeps sign, shifts use b[4:0]
        a = 32'hFFFFFFFF; b = 32'h1; op = 4'd3; #1; if (y !== 1) begin errors = errors + 1; $display("FAIL slt"); end
        op = 4'd4; #1; if (y !== 0) begin errors = errors + 1; $display("FAIL sltu"); end
        a = 32'h80000000; b = 32'd35; op = 4'd7; #1; if (y !== 32'hF0000000) begin errors = errors + 1; $display("FAIL sra b[4:0]"); end
        $display("ALU: %0d checks, %0d errors -> %s", checks, errors, errors ? "FAIL" : "PASS");
        $finish(errors ? 1 : 0);
    end
endmodule
