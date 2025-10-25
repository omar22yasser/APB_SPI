`default_nettype none
module SPI_Slave (
    input  wire          tx_valid,SS_n,MOSI,clk,rst_n,
    input  wire    [7:0] tx_data, 
    output reg           MISO,rx_valid,
    output wire    [9:0] rx_data
);

localparam IDLE=3'd0,CHK_CMD=3'd1,WRITE=3'd2,
           READ_ADD=3'd3,READ_DATA=3'd4;

reg  [2:0] current_state , next_state ;
reg  [3:0] counter_10;
reg  [3:0] counter_8;
wire       tick_10 ;
wire       tick_8 ;
reg        start_10,start_8;
reg        address_signal_reg;
reg        address_signal;
reg        address_signal_reg_en;
reg  [9:0] recieved_data;

assign   tick_10 = ( counter_10 == 4'd10);  
assign   tick_8 = ( counter_8 == 4'd8);
assign   rx_data = recieved_data;

always @(posedge clk or negedge rst_n )
begin
    if ( !rst_n )
    recieved_data  <= 10'b0;
    else if (SS_n)
    recieved_data  <= 10'b0;
    else 
	recieved_data <= {recieved_data[8:0] , MOSI };
end

always @(posedge clk or negedge rst_n )
begin
    if ( !rst_n )
    address_signal_reg  <= 1'b0;
    else if (address_signal_reg_en)
	address_signal_reg <= address_signal;
end

always @(posedge clk or negedge rst_n )
begin
    if ( !rst_n )
    counter_10 <= 4'b0;
    else if(counter_10 != 4'd10 && start_10) 
        counter_10 <= counter_10 + 4'd1 ;
    else 
	counter_10 <= 4'd0;
end

always @(posedge clk or negedge rst_n )
begin
    if ( !rst_n )
    counter_8 <= 4'b0;
    else if(counter_8 != 4'd8 && start_8) 
        counter_8 <= counter_8 + 4'd1 ;
    else 
	counter_8 <= 4'd0;
end



always @( posedge clk or negedge rst_n)
begin
    if ( !rst_n )
    current_state <= IDLE;
    else begin
    current_state <= next_state;
    end
end

always @(*)
begin
    case (current_state)
    IDLE : begin
        if(!SS_n)
        next_state = CHK_CMD;
        else
        next_state = IDLE;
    end
    CHK_CMD : begin
        if(SS_n == 0 && MOSI == 0)
        next_state = WRITE;
        else if(MOSI && !address_signal_reg)
         next_state =READ_ADD; 
        else if(MOSI && address_signal_reg) 
         next_state =READ_DATA; 
        else
        next_state = CHK_CMD;
    end
    WRITE : begin
        if(SS_n == 1)
        next_state = IDLE;
        else if (tick_10 )
        next_state = IDLE;
        else 
        next_state = WRITE;
            end
    READ_ADD : begin
        if(SS_n)
        next_state = IDLE;
        else if (!SS_n && ~ tick_10) begin
         next_state = READ_ADD;   
        end
        else if (!SS_n && tick_10) begin
         next_state = IDLE;   
        end
    end
    READ_DATA : begin
        if(SS_n)
        next_state = IDLE;
        else if ( ~ tick_8) begin
         next_state = READ_DATA;   
        end
        else if (tick_8) begin
         next_state = IDLE;   
        end
    end
    default : begin
       next_state =IDLE; 
    end
    endcase
end

always @(*)
begin
    MISO = 1'b0;
    rx_valid =1'b0;
    start_10 = 1'b0;
    start_8 = 1'b0;
    address_signal =1'b0;
    address_signal_reg_en=1'b0;
    case (current_state)
    IDLE : begin
    end
    CHK_CMD : begin
        /*if(!MOSI)
        start_10 = 1'b1;
        else 
         start_10 = 1'b1;*/
    end
    WRITE : begin
        if (~ tick_10) begin
        rx_valid = 1'b0; 
        start_10 = 1'b1; 
        end
        else begin
        rx_valid = 1'b1;
        start_10 = 1'b0;   
        end
    end
    READ_ADD : begin
        if (~ tick_10) begin
        rx_valid = 1'b0; 
        start_10 = 1'b1;
        address_signal =1'b0;
        address_signal_reg_en=1'b0;  
        end
        else begin
        rx_valid = 1'b1;
        start_10 = 1'b0;
        address_signal =1'b1;
        address_signal_reg_en=1'b1;    
        end
    end
    READ_DATA : begin          // Assign Miso 
        if (~ tick_10 && ~tx_valid) begin
        rx_valid = 1'b0; 
        start_10 = 1'b1;
        address_signal_reg_en=1'b0;  
        end
        else if (tick_10 && ~tx_valid) begin
        rx_valid = 1'b1;
        start_10 = 1'b0;
        start_8 = 1'b0;
        address_signal_reg_en=1'b0;    
        end
        else if (tx_valid && ~tick_8) begin
        rx_valid = 1'b0;
        start_10 = 1'b0;
        start_8 = 1'b1;
        MISO = tx_data [7-counter_8];
        address_signal_reg_en=1'b0;    
        end
        else if ( tx_valid && tick_8) begin
        rx_valid = 1'b0;
        start_10 = 1'b0;
        start_8 = 1'b0;
        address_signal_reg_en=1'b1;    
        end
    end
    default : begin
    MISO = 1'b0;
    rx_valid =1'b0;
    start_10 = 1'b0;
    start_8 = 1'b0;
    address_signal =1'b0;
    address_signal_reg_en=1'b0;
    end
    endcase
end

endmodule
