module seven_segment_display(data_in, grounds, display, clk);

	input wire [15:0] data_in;
	input clk;

	output reg [3:0] grounds;
	output reg [6:0] display;

	reg [3:0] data [3:0];
	reg [1:0] count;
	reg [25:0] temp_clk;

	always @(*)
		 begin
			  case (data[count])
					0 : display = 7'b1111110;
					1 : display = 7'b0110000;
					2 : display = 7'b1101101;
					3 : display = 7'b1111001;
					4 : display = 7'b0110011;
					5 : display = 7'b1011011;
					6 : display = 7'b1011111;
					7 : display = 7'b1110000;
					8 : display = 7'b1111111;
					9 : display = 7'b1111011;
					'ha : display = 7'b1110111;
					'hb : display = 7'b0011111;
					'hc : display = 7'b1001110;
					'hd : display = 7'b0111101;
					'he : display = 7'b1001111;
					'hf : display = 7'b1000111;
			  endcase
		 end

		 
	always @*
		begin 
			data[3] = data_in[15:12];
			data[2] = data_in[11:8];
			data[1] = data_in[7:4];
			data[0] = data_in[3:0];
		end
		
		
	always @(posedge clk)
		temp_clk <= temp_clk + 1;
	 
	 
	always @(posedge temp_clk[15])
		begin
			grounds <= {grounds[2:0], grounds[3]};
			count <= count + 1;
		end


	initial 
		begin
			count = 2'b0;
			grounds = 4'b1110;
			temp_clk = 0;
		end
	
	
endmodule