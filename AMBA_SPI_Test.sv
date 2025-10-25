`timescale 1ns/1ps
`default_nettype none

module tb_AMBA_SPI_Wrapper;

  // Clock & Reset
  reg PCLK;
  reg PRESETn;

  // APB signals
  reg        PSEL, PENABLE, PWRITE;
  reg  [7:0] PADDR, PWDATA;
  wire [15:0] PRDATA;
  wire       PREADY, PSLVERR;

  // SPI signals
  reg  SS_n, MOSI;
  wire MISO;

  // Mode
  reg APB_MODE;

  // Clock generation (50 MHz -> 20 ns period)
  initial PCLK = 0;
  always #10 PCLK = ~PCLK;

  // DUT instantiation
  AMBA_SPI_Wrapper dut (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PWRITE  (PWRITE),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR),
    .APB_MODE(APB_MODE),
    .SS_n    (SS_n),
    .MOSI    (MOSI),
    .MISO    (MISO)
  );

  // ---------------------------------------------------
  // TASKS for APB transactions
  // ---------------------------------------------------
  task apb_write(input [7:0] addr, input [7:0] data);
    begin
      @(negedge PCLK);
      PSEL   = 1;
      PENABLE= 0;
      PWRITE = 1;
      PADDR  = addr;
      PWDATA = data;
      @(posedge PCLK);
      @(posedge PCLK);
      PENABLE = 1; // ACCESS phase
      @(posedge PCLK);
      PSEL   = 0;
      PENABLE= 0;
      PWRITE = 0;
    end
  endtask

  task apb_read(input [7:0] addr);
    begin
      @(negedge PCLK);
      PSEL   = 1;
      PENABLE= 0;
      PWRITE = 0;
      PADDR  = addr;
      @(negedge PCLK);
      PENABLE = 1; // ACCESS phase
      @(posedge PCLK);
      $display("APB READ @0x%0h = 0x%0h", addr, PRDATA);
      @(negedge PCLK);
      PSEL   = 0;
      PENABLE= 0;
    end
  endtask

  // ---------------------------------------------------
  // Test stimulus
  // ---------------------------------------------------
  initial begin
    // Init
    PRESETn = 0;
    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;
    SS_n    = 1;
    MOSI    = 0;
    APB_MODE= 1; // use APB as data source for SPI
    #100;

    PRESETn = 1; // Release reset
    #50;

    // Write TXDATA (0x0C) with value 0xA5
    apb_write(8'h0C, 8'hA5);

    // Read back STATUS (0x04)
    apb_read(8'h04);

    // Read back RXDATA (0x08)
    apb_read(8'h08);

    // Simulate a simple SPI transaction: send 10 bits via MOSI
    // SS_n = 0; // select active
    // (10) begin
    // @(negedge PCLK);
    // MOSI = $random;  // random bits
    // end
    // @(negedge PCLK);
    // SS_n = 1; // de-select

    // Read RXDATA again
    //apb_read(8'h08);

    #200;
    $finish;
  end

endmodule

