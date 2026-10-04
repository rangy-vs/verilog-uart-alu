IVERILOG ?= iverilog
FLAGS    ?= -g2012 -Wall

test: alu uart

alu:
	mkdir -p build
	$(IVERILOG) $(FLAGS) -o build/alu.out rtl/alu.v tb/tb_alu.v
	cd build && vvp alu.out

uart:
	mkdir -p build
	$(IVERILOG) $(FLAGS) -o build/uart.out rtl/uart_tx.v rtl/uart_rx.v tb/tb_uart.v
	cd build && vvp uart.out

clean:
	rm -rf build
