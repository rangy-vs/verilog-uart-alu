`timescale 1ns/1ps
// UART receiver, 8N1, samples at mid-bit. Two-flop synchroniser on the async input.
// `valid` pulses one clock when a byte with a correct stop bit is received;
// `frame_err` goes high if the stop bit was 0.
module uart_rx #(parameter CLKS_PER_BIT = 16) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,
    output reg        frame_err
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg rx_s1, rx_s2;                       // metastability protection
    always @(posedge clk) begin rx_s1 <= rx; rx_s2 <= rx_s1; end

    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  bit_idx;

    always @(posedge clk) begin
        valid <= 1'b0;
        if (rst) begin
            state <= IDLE; cnt <= 0; bit_idx <= 0; data <= 0; frame_err <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cnt <= 0; bit_idx <= 0;
                    if (!rx_s2) state <= START;                 // falling edge = start bit
                end
                START: begin                                    // re-check at mid start bit
                    if (cnt == (CLKS_PER_BIT - 1) / 2) begin
                        cnt <= 0;
                        state <= rx_s2 ? IDLE : DATA;           // glitch rejection
                    end else cnt <= cnt + 1;
                end
                DATA: begin
                    if (cnt == CLKS_PER_BIT - 1) begin
                        cnt <= 0; data <= {rx_s2, data[7:1]};   // LSB first
                        if (bit_idx == 3'd7) state <= STOP; else bit_idx <= bit_idx + 1;
                    end else cnt <= cnt + 1;
                end
                STOP: begin
                    if (cnt == CLKS_PER_BIT - 1) begin
                        cnt <= 0; state <= IDLE;
                        if (rx_s2) begin valid <= 1'b1; frame_err <= 1'b0; end
                        else frame_err <= 1'b1;
                    end else cnt <= cnt + 1;
                end
            endcase
        end
    end
endmodule
