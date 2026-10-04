# Verilog: RV32I ALU + UART (8N1)

![ci](../../actions/workflows/ci.yml/badge.svg)

Synthesizable RTL with self-checking testbenches, simulated with [Icarus Verilog](https://steveicarus.github.io/iverilog/).

| Module | Description |
|---|---|
| `alu.v` | 32-bit ALU with the RV32I integer ops (add, sub, sll, slt, sltu, xor, srl, sra, or, and) + zero flag |
| `uart_tx.v` | 8N1 transmitter, parameterized `CLKS_PER_BIT` |
| `uart_rx.v` | 8N1 receiver: 2-flop synchronizer, mid-bit sampling, start-bit glitch rejection, framing-error flag |

```bash
make test
# ALU: 5641 checks, 0 errors -> PASS
# UART: 106 bytes sent, 106 received, 0 errors -> PASS
```
Waveforms are written to `build/alu.vcd` and `build/uart.vcd` (open with GTKWave).

## Verification approach
- **ALU:** every op × every pair of 8 corner values (0, 1, −1, INT_MIN, INT_MAX, patterns) plus 5,000 seeded random vectors. The reference model is written with loops and bit tricks, deliberately *not* reusing the RTL's operators, and explicit checks cover signed-vs-unsigned compare and `sra` using only `b[4:0]`.
- **UART:** TX→RX loopback with a scoreboard (6 directed bytes + 100 random back-to-back), plus a second hand-driven receiver for **fault injection**: a too-short start glitch must be ignored, a low stop bit must raise `frame_err` without producing a byte, and the receiver must recover on the next good frame.
- **Mutation-checked:** I deliberately broke the RTL (changed `sra` to a logical shift; broke the RX sampling) and confirmed the testbenches fail loudly, so a green run means something.

## Limits
Simulation only, with no FPGA constraints or synthesis run yet. The natural next step is synthesizing with Yosys or Vivado for a board, wiring the UART to the ALU as a command-driven calculator, and adding a register file to build toward a small CPU core.
