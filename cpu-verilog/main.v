//Main module


module main (
			output wire [3:0] rowwrite,
			input [3:0] colread,
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

//memory map is defined here
localparam	BEGINMEM1=16'h0000,
		ENDMEM1=16'hcfff,
		KEYPAD=16'hd000,
		SEVENSEG=16'hd002,
		BEGINMEM2=16'hf000,
		ENDMEM2=16'hffff;
//  memory chip
reg [15:0] memory [0:255]; 

// cpu's input-output pins
wire [15:0] data_out;
reg [15:0] data_in;
wire [15:0] address;
wire memwt;


seven_segment_display ss1 (data_all, grounds, display, clk);

keypad  kp1(rowwrite,colread,clk,ack,statusordata,keyout);

bird br1 (clk, data_in, data_out, address, memwt);


//multiplexer for cpu input
always @*
	if ( ((BEGINMEM1<=address) && (address<=ENDMEM1)) || ((BEGINMEM2<=address) && (address<=ENDMEM2)) )
		begin
			data_in=memory[address];
			ack=0;
			statusordata=0;
		end
	else if (address==KEYPAD+1)
		begin	
			statusordata=1;
			data_in=keyout;
			ack=0;
		end
	else if (address==KEYPAD)
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

always @(posedge clk) //data output port of the cpu
	if (memwt)
		if ( ((BEGINMEM1<=address) && (address<=ENDMEM1)) || ((BEGINMEM2<=address) && (address<=ENDMEM2)) )
			memory[address]<=data_out;
		else if ( SEVENSEG==address) 
			data_all<=data_out;


initial 
	begin
		data_all=0;
		ack=0;
		statusordata=0;
		$readmemh("ram.dat", memory);
	end

endmodule