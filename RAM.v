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
    if(~rst_n)
      dout <= 'b0;
    else
      case(din[9:8])
        wr_addr, rd_addr: begin
          tx_valid <= 1'b0;
          if(rx_valid) begin //must wait for the rx_valid to be high in order to accept the operation
            addr <= din[7:0]; //holding din[7:0] as an address
          end 
        end

        wr_data: begin
          tx_valid <= 1'b0;
          if(rx_valid) begin //must wait for the rx_valid to be high in order to accept the operation
            memory[addr] <= din[7:0]; //Write din[7:0] in the memory with write address held previously
          end
        end

        rd_data: begin
          dout <= memory[addr]; //dout holds the word read from the memory
          tx_valid <= 1'b1;
        end
      endcase
  end

endmodule