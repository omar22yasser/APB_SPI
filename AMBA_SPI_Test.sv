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

  //SPI test Variables
  reg [7:0] test_addr;
  reg [7:0] test_data;
  reg [7:0] test_addr_2;
  reg [7:0] test_data_2;
  reg [7:0] read_data;
  reg [7:0] temp;

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
      @(negedge PCLK);
    end
  endtask

  task apb_read(input [7:0] addr);
    begin
      @(negedge PCLK);
      PSEL   = 1;
      PENABLE= 0;
      PWRITE = 0;
      PADDR  = addr;
      @(posedge PCLK);
      @(posedge PCLK);
      PENABLE = 1; // ACCESS phase
      @(posedge PCLK);
      @(negedge PCLK);
      $display("APB READ @0x%0h = 0x%0h", addr, PRDATA);
      PSEL   = 0;
      PENABLE= 0;
      @(negedge PCLK);
    end
  endtask

    //SPI tasks
    // --- Helper tasks ---
  task send_bit(input bit b);
    begin
      MOSI = b;
      #20;  // one clock cycle (20ns)
    end
  endtask

  task send_byte(input [7:0] data);
    integer j;
    begin
      for (j=7; j>=0; j=j-1) begin
        send_bit(data[j]);
      end
    end
  endtask

  // ---------------------------------------------------
  // Test stimulus
  // ---------------------------------------------------
  initial begin

    // SPI test values
    test_addr = 8'hA5;  //10100101
    test_data = 8'h3C;  //00111100
    test_addr_2 = 8'hA6;  //10100110
    test_data_2 = 8'h3B;  //00111101

    // Init
    PRESETn = 0;
    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;
    SS_n  = 1;
    MOSI  = 1;
    APB_MODE= 1; // use APB as data source for SPI
    #100;

    PRESETn = 1; // Release reset
    #50;

    // Write TXDATA (0x0C) with value 0xA5
    apb_write(8'h0C, 8'hA5);

    apb_write(8'h0C, 8'hA8);

    //SPI write test

    // --- WRITE ADDRESS ---
    #40;
    SS_n = 0;
    #20
    MOSI  = 0;
    #20
    send_bit(0); send_bit(0);   // "00" = write address
    send_byte(test_addr);
    #20
    SS_n = 1;
    #40;

    
    // --- WRITE DATA ---
    SS_n = 0;
    #20
    MOSI  = 0;
    #20
    send_bit(0); send_bit(1);   // "01" = write data
    send_byte(test_data);
    SS_n = 1;
    #40;

    // Read back RXDATA (0x08)
    apb_read(8'h08);

    // Read back STATUS (0x04)
    //apb_read(8'h04);

    // Read back RXDATA (0x08)
    //apb_read(8'h08);

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

