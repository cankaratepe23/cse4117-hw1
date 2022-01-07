//Main module


module main (
			output wire [3:0] rowwrite,
			input [3:0] colread,
			output reg [7:0] leds,
			input clk,
			output wire [3:0] grounds,
			output wire [6:0] display,
			input pushbutton //may be used as clock
			);

reg [15:0] data_all;
wire [3:0] keyout;
reg [25:0] clk1;
reg [1:0] ready_buffer;
reg ack;
reg statusordata;
reg sram_ld;

//memory map is defined here
localparam	BEGINMEM1=16'h0000,
		ENDMEM1=16'h00CF,
		KEYPAD=16'h00D0,
		SEVENSEG=16'h00D2,
		BEGINMEM2=16'h00D3,
		ENDMEM2=16'h0100;
//  memory chip
reg [15:0] memory [0:255];

// cpu's input-output pins
wire [15:0] data_out;
reg [15:0] data_in;
// reg  [15:0] mem_out;
wire [15:0] address;
wire [15:0] mapped_address;
wire memwt;
reg [15:0] ssss;

assign mapped_address = (address > 16'h0100) ? 16'h0100 - (16'hFFFF - address) : address;

seven_segment_display ss1 (data_all, grounds, display, clk);

keypad  kp1(rowwrite,colread,clk,ack,statusordata,keyout);

bird br1 (clk, data_in, data_out, address, memwt);


//multiplexer for cpu input7

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
		else
			begin
				data_in=16'hf345; //any number
				ack=0;
				statusordata=0;
			end

//multiplexer for cpu output 

always @(posedge clk) begin //data output port of the cpu
	if (memwt)
		begin
			if ( ((BEGINMEM1<=mapped_address) && (mapped_address<=ENDMEM1)) || ((BEGINMEM2<=mapped_address) && (mapped_address<=ENDMEM2)) )
				memory[mapped_address]<=data_out;
			else if ( SEVENSEG==mapped_address) 
				data_all<=data_out;
		end
	//mem_out=memory[mapped_address];
end

/*
always @*
	begin
		leds[0] <= rowwrite[0];
		leds[1] <= rowwrite[1];
		leds[2] <= rowwrite[2];
		leds[3] <= rowwrite[3];
		ssss <= {8'b0, colread, rowwrite};
	end
	
always @(posedge pushbutton)
	begin
	leds[4] <= ~leds[4];
	end
*/

initial 
	begin
		data_all=0;
		ack=0;
		statusordata=0;
		$readmemh("ram.dat", memory);
	end

endmodule