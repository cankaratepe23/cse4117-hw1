//Main module
module main (
			output wire [3:0] rowwrite,
			input [3:0] colread,
			output reg [7:0] leds,
			input clk,
			output wire [3:0] grounds,
			output wire [6:0] display,
			input push_button
			);

reg [15:0] data_all;
wire [3:0] keyout;

reg ack;
reg statusordata;

reg timer_ack;
reg timer_out_select;
wire [15:0] timer_out;

//	memory map is defined here
localparam	BEGINMEM1=16'h0000,
				ENDMEM1=16'h00DE,
				KEYPAD=16'h00DF,
				TIMER=16'h00E1,
				SEVENSEG=16'h00E3,
				BEGINMEM2=16'h00E4,
				ENDMEM2=16'h00FF;
		
//	memory chip
reg [15:0] memory [0:255];

//	cpu's input-output pins
wire memwt;
wire [15:0] data_out;
wire [15:0] address;
wire [15:0] mapped_address;
reg [15:0] data_in;


assign mapped_address = (address > ENDMEM2) ? ENDMEM2 - (16'hFFFF - address) : address;

seven_segment_display ss1 (data_all, grounds, display, clk);

keypad  kp1(rowwrite,colread,clk,ack,statusordata,keyout);

bird br1 (clk, data_in, data_out, address, memwt);

timer tmr (clk, timer_ack, timer_out_select, ~push_button, timer_out);


//multiplexer for cpu input
always @*
		if ( ((BEGINMEM1<=mapped_address) && (mapped_address<=ENDMEM1)) || ((BEGINMEM2<=mapped_address) && (mapped_address<=ENDMEM2)) )
			begin
				data_in=memory[mapped_address];
				ack=0;
				statusordata=0;
			end
		else if (mapped_address==KEYPAD+1)
			begin	
				statusordata=1;
				data_in=keyout;
				ack=0;
			end
		else if (mapped_address==KEYPAD)
			begin
				statusordata=0;
				data_in=keyout;
				ack=1;
			end
		else if (mapped_address == TIMER + 1)
			begin	
				timer_out_select = 1;
				data_in = timer_out;
				timer_ack = 0;
			end
		else if (mapped_address == TIMER)
			begin
				timer_out_select = 0;
				data_in = timer_out;
				timer_ack = 1;
			end
		else
			begin
				data_in=16'h0599; //not any number
				ack=0;
				statusordata=0;
			end

//multiplexer for cpu output 

always @(posedge clk) begin //data output port of the cpu
	if (memwt)
		begin
			if ( ((BEGINMEM1<=mapped_address) && (mapped_address<=ENDMEM1)) || ((BEGINMEM2<=mapped_address) && (mapped_address<=ENDMEM2)) )
				memory[mapped_address]<=data_out;
			else if ( SEVENSEG == mapped_address) 
				data_all<=data_out;
		end
end

always @*
	leds[0] = ~push_button;
	
initial 
	begin
		leds=0;
		data_all=0;
		ack=0;
		statusordata=0;
		$readmemh("ram.dat", memory);
	end

endmodule