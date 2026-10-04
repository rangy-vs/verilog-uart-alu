`timescale 1ns/1ps
// UART transmitter, 8N1. Pulse `start` for one clock while !busy to send `data`.
module uart_tx #(parameter CLKS_PER_BIT = 16) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       start,
    output reg        tx,
    output wire       busy
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0]  state;
    reg [15:0] cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; tx <= 1'b1; cnt <= 0; bit_idx <= 0; shreg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1; cnt <= 0; bit_idx <= 0;
                    if (start) begin shreg <= data; state <= START; end
                end
                START: begin
                    tx <= 1'b0;
                    if (cnt == CLKS_PER_BIT - 1) begin cnt <= 0; state <= DATA; end
                    else cnt <= cnt + 1;
                end
                DATA: begin
                    tx <= shreg[0];                       // LSB first
                    if (cnt == CLKS_PER_BIT - 1) begin
                        cnt <= 0; shreg <= {1'b0, shreg[7:1]};
                        if (bit_idx == 3'd7) state <= STOP; else bit_idx <= bit_idx + 1;
                    end else cnt <= cnt + 1;
                end
                STOP: begin
                    tx <= 1'b1;
                    if (cnt == CLKS_PER_BIT - 1) begin cnt <= 0; state <= IDLE; end
                    else cnt <= cnt + 1;
                end
            endcase
        end
    end
endmodule
