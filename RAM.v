`default_nettype none
module RAM 
#(
parameter MEM_DEPTH = 256,
parameter ADDR_SIZE = 8
)
(
input wire clk, rst_n, rx_valid,
input wire [9:0] din,
output reg [7:0] dout,
output reg tx_valid
);

localparam wr_addr = 2'b00, wr_data = 2'b01, rd_addr = 2'b10, rd_data = 2'b11;
reg [ADDR_SIZE-1:0] memory [MEM_DEPTH-1:0];
reg [ADDR_SIZE-1:0] addr;

always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n) begin
      dout <= 'b0;
      tx_valid <= 'b0;
      addr <= 'b0;
    end
    else if(rx_valid) begin //must wait for the rx_valid to be high in order to accept th operation
      tx_valid <= 1'b0;
      case(din[9:8])
        wr_addr, rd_addr: begin
        tx_valid <= 1'b0;
        addr <= din[7:0]; //holding din[7:0] as an address
        end

        wr_data: begin
        tx_valid <= 1'b0;
        memory[addr] <= din[7:0];
        end

        rd_data: begin
        dout <= memory[addr]; //dout holds the word read from the memory
        tx_valid <= 1'b1;
        end
      endcase
      end 

  end

endmodule
