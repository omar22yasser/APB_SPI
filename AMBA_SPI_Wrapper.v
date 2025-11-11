module AMBA_SPI_Wrapper (
    //ABP input 
    input wire PCLK,PRESETn,
    input wire PSEL,PENABLE,PWRITE,
    input wire [7:0] PADDR,PWDATA,

    input wire APB_MODE,

    //SPI input
    input wire SS_n, MOSI,

    //ABP output
    output wire [15:0] PRDATA, 
    output wire PREADY,PSLVERR,

    //SPI output
    output wire MISO
);

reg [9:0] RX_DATA_reg;

//SPI Wires
wire rx_valid_out,tx_valid_out;
wire [9:0] RX_DATA;

//ABP Wires
wire [7:0] TX_DATA;

always @(posedge rx_valid_out) begin
  RX_DATA_reg = RX_DATA;
end

SPI_Wrapper  SPI_Wrapper_inst (
    .clk(PCLK),
    .rst_n(PRESETn),
    .SS_n(SS_n),
    .MOSI(MOSI),
    .MISO(MISO),
    .TX_DATA(TX_DATA),
    .APB_MODE(APB_MODE),
    .RX_DATA(RX_DATA),
    .rx_valid_out(rx_valid_out),
    .tx_valid_out(tx_valid_out)
  );


AMBA_APB  AMBA_APB_inst (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
     // extra connections
    .SPI_CTRL_reg(),              // if you keep control reg
    .SPI_STATUS_reg({rx_valid_out, tx_valid_out}),
    .SPI_RXDATA_reg(RX_DATA_reg),
    .SPI_TXDATA_reg(TX_DATA)
  );

endmodule