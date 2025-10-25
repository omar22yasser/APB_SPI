`default_nettype none
module SPI_Wrapper (
  input wire clk, rst_n, SS_n, MOSI,
  output wire MISO,

  // APB modification
  input wire [7:0] TX_DATA,
  input wire APB_MODE,
  output wire [9:0] RX_DATA, 
  output wire rx_valid_out,tx_valid_out
);

wire [7:0] Ram_dout;
wire [9:0] Ram_din;
wire  rx_valid, tx_valid;

// APB modification
wire [7:0] tx_data_spi; //Input to SPI

assign rx_valid_out = rx_valid;
assign tx_valid_out = tx_valid;
assign RX_DATA = Ram_din;
assign tx_data_spi = APB_MODE ? TX_DATA : Ram_dout;

RAM #(.ADDR_SIZE(8), .MEM_DEPTH(256)) ram_inst(
.clk(clk), 
.rst_n(rst_n), 
.rx_valid(rx_valid),  
.din(Ram_din),
.dout(Ram_dout),
.tx_valid(tx_valid)
);

//discuss if there is internal parameters
SPI_Slave U0_SS(
.clk(clk), 
.rst_n(rst_n), 
.MOSI(MOSI),
.MISO(MISO),
.SS_n(SS_n),
.rx_data(Ram_din),
.rx_valid(rx_valid), 
.tx_data(tx_data_spi),
.tx_valid(tx_valid)
);


endmodule