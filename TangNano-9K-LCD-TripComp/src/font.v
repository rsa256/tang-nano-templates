module font(clk, char, line, re, data_out);
   output[7:0] data_out;
   input [6:0] char;
   input [2:0] line;
   input clk, re;
 
   reg [7:0] font [0:128*8-1];
	reg [0:7] d;
	assign data_out = {d[7],d[6],d[5],d[4],d[3],d[2],d[1],d[0]};
 
   initial $readmemh("font.hex", font);
 
   always @(posedge clk) begin
		if (re)
			d <= font[{ char, line }];
   end
        
endmodule
