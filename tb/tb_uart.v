`timescale 1ns/1ps
// UART loopback test: tx -> rx. Also checks glitch rejection and framing-error detection.
module tb_uart;
    localparam CPB = 16;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;                                           // 100 MHz

    reg  [7:0] tx_data; reg tx_start = 0;
    wire       line, tx_busy;
    wire [7:0] rx_data; wire rx_valid, rx_ferr;

    uart_tx #(.CLKS_PER_BIT(CPB)) tx (.clk(clk), .rst(rst), .data(tx_data), .start(tx_start), .tx(line), .busy(tx_busy));
    uart_rx #(.CLKS_PER_BIT(CPB)) rx (.clk(clk), .rst(rst), .rx(line), .data(rx_data), .valid(rx_valid), .frame_err(rx_ferr));

    // second receiver driven by hand to inject faults
    reg  bad_line = 1;
    wire [7:0] bad_data; wire bad_valid, bad_ferr;
    uart_rx #(.CLKS_PER_BIT(CPB)) rx_bad (.clk(clk), .rst(rst), .rx(bad_line), .data(bad_data), .valid(bad_valid), .frame_err(bad_ferr));

    integer errors = 0, sent = 0, got = 0, i;
    reg [7:0] queue [0:255];
    integer bad_valid_count = 0;
    always @(posedge clk) if (bad_valid) bad_valid_count = bad_valid_count + 1;

    // scoreboard: every received byte must match the next byte sent
    always @(posedge clk) if (rx_valid) begin
        if (rx_data !== queue[got]) begin
            errors = errors + 1; $display("FAIL byte %0d: got %h exp %h", got, rx_data, queue[got]);
        end
        got = got + 1;
    end

    task send(input [7:0] b);
        begin
            wait (!tx_busy); @(posedge clk);
            queue[sent] = b; sent = sent + 1;
            tx_data = b; tx_start = 1; @(posedge clk); tx_start = 0;
        end
    endtask

    task bit_bang(input [7:0] b, input stop_level);                 // drive bad_line manually
        integer j;
        begin
            bad_line = 0; repeat (CPB) @(posedge clk);
            for (j = 0; j < 8; j = j + 1) begin bad_line = b[j]; repeat (CPB) @(posedge clk); end
            bad_line = stop_level; repeat (CPB) @(posedge clk);
            bad_line = 1; repeat (CPB) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("uart.vcd"); $dumpvars(0, tb_uart);
        repeat (5) @(posedge clk); rst = 0; repeat (5) @(posedge clk);

        send(8'h00); send(8'hFF); send(8'hA5); send(8'h5A); send(8'h01); send(8'h80);
        for (i = 0; i < 100; i = i + 1) send($urandom);             // random back-to-back traffic
        wait (!tx_busy); repeat (CPB * 4) @(posedge clk);

        // fault injection on the hand-driven receiver
        bad_line = 0; repeat (CPB / 4) @(posedge clk); bad_line = 1; repeat (CPB * 4) @(posedge clk);
        if (bad_valid_count != 0) begin errors = errors + 1; $display("FAIL: glitch accepted as start bit"); end
        bit_bang(8'h3C, 1'b0);                                      // stop bit low -> framing error
        if (!bad_ferr || bad_valid_count != 0) begin errors = errors + 1; $display("FAIL: framing error not flagged"); end
        bit_bang(8'h3C, 1'b1);                                      // recovers and accepts a good byte
        if (bad_valid_count != 1 || bad_data !== 8'h3C || bad_ferr) begin errors = errors + 1; $display("FAIL: no recovery after framing error"); end

        if (got != sent) begin errors = errors + 1; $display("FAIL: sent %0d, received %0d", sent, got); end
        $display("UART: %0d bytes sent, %0d received, %0d errors -> %s", sent, got, errors, errors ? "FAIL" : "PASS");
        $finish(errors ? 1 : 0);
    end

    initial begin #20_000_000; $display("TIMEOUT"); $finish(1); end
endmodule
