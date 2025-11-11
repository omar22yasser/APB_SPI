module AMBA_APB (
    input wire PCLK,PRESETn,
    input wire PSEL,PENABLE,PWRITE,
    input wire [7:0] PADDR,PWDATA,

    output reg [15:0] PRDATA, //16 bits
    output reg PREADY,PSLVERR,

    input        SPI_CTRL_reg,
    input  [1:0] SPI_STATUS_reg,
    input  [9:0] SPI_RXDATA_reg,
    output [7:0] SPI_TXDATA_reg
);

wire SPI_CTRL;
wire [1:0] SPI_STATUS;
wire [9:0] SPI_RXDATA;
reg [7:0] SPI_TXDATA;

reg [7:0] PADDR_latched;

assign SPI_CTRL = SPI_CTRL_reg;
assign SPI_STATUS = SPI_STATUS_reg;
assign SPI_RXDATA = SPI_RXDATA_reg;
assign SPI_TXDATA_reg = SPI_TXDATA; 

parameter IDLE   = 2'b00,
          SETUP  = 2'b01,
          ACCESS = 2'b10;

reg [1:0] current_state, next_state;

always@(posedge PCLK)
begin
    if(!PRESETn)
    current_state <= IDLE;
    else 
    current_state <= next_state;
end

//next state logic
always @(*)
begin
 case(current_state)
    IDLE:begin
        if(PSEL && !PENABLE)
        next_state = SETUP;
        else
        next_state = IDLE;
    end

    SETUP:begin
        if(!PSEL)
        next_state = IDLE;
        else 
        next_state = ACCESS; //always go to access after 1 clk cycle
    end

    ACCESS: begin
        if(!PSEL)
        next_state = IDLE;
        else if (PSEL && !PENABLE)
        next_state = SETUP;
        else
        next_state = ACCESS;
    end
 endcase
end 

// save address in setup phase
always @(posedge PCLK)
begin
    if(!PRESETn) begin
    PADDR_latched <= 8'b0;
    SPI_TXDATA <= 8'b0;
    end
    else if(current_state == SETUP)
    PADDR_latched <= PADDR;
    else if (current_state == ACCESS && PWRITE) begin
        case (PADDR_latched)
            8'h0C: SPI_TXDATA <= PWDATA; // Write TXDATA
        endcase
    end
    else if (current_state == ACCESS && !PWRITE) begin
        case(PADDR_latched)
                8'h00: PRDATA = {15'b0,SPI_CTRL};   //0000 0000
                8'h04: PRDATA = {14'b0,SPI_STATUS}; //0000 0100
                8'h08: PRDATA = {6'b0,SPI_RXDATA}; //10bits rx data //0000 1000
                default: PRDATA = 16'h00;
        endcase
    end
end

//output logic
always @(*)
begin
 PRDATA = 16'h00;
 case(current_state)
    IDLE: begin
        PREADY = 1'b0;
        PSLVERR = 1'b0;
    end

    //setup
    SETUP: begin
        PREADY = 1'b0;
        PSLVERR = 1'b0;
    end


    ACCESS: begin
        PREADY = 1'b1;
        PSLVERR = 1'b0;     
    end
 endcase
end 
    
endmodule

