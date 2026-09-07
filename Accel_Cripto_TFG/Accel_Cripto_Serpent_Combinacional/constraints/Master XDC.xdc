## Clock 100 MHz
set_property PACKAGE_PIN E3 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -period 10.000 -name sys_clk [get_ports CLK100MHZ]

## UART
set_property PACKAGE_PIN C4 [get_ports UART_RXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]
set_property PACKAGE_PIN D4 [get_ports UART_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]

## Reset (boton central BTNC)
set_property PACKAGE_PIN N17 [get_ports BTN_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports BTN_RESET]