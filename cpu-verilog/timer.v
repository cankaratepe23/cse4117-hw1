module timer(
				input clk,
				input ack,
				input output_select,
				input key_pressed,
				output reg [15:0] data_out
				);
				
		
reg [26:0] clk1;
reg [15:0] data;
reg [15:0] current_time; 


always @(posedge clk)
	begin
		if (clk1 == 'h2FAF080)
			begin
				clk1 <= 0;
				current_time <= current_time + 1;
			end
		else 
			clk1 <= clk1 + 1;
	end
	

always @(posedge clk)
	if (key_pressed && ready == 0)
		begin
			data <= current_time;
			ready <= 1;
		end
	else if (ack == 1 && ready == 1)
		ready <= 0;

		
		
always @*
	if (output_select == 1)
		data_out = {15'b0, ready};
	else
		data_out = data;

initial 
	begin
		clk1 = 0;
		ready = 0;
		data = 0;
		current_time = 0;		
	end
endmodule