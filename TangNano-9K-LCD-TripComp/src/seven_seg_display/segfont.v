module segfont(digit, data_out);
   input [3:0] digit;
   output reg [6:0] data_out;
 
   always @(digit) begin
      case(digit)
        4'h0: data_out = 7'b1111110;
        4'h1: data_out = 7'b0110000;
        4'h2: data_out = 7'b1101101;
        4'h3: data_out = 7'b1111001;
        4'h4: data_out = 7'b0110011;
        4'h5: data_out = 7'b1011011;
        4'h6: data_out = 7'b1011111;
        4'h7: data_out = 7'b1110000;
        4'h8: data_out = 7'b1111111;
        4'h9: data_out = 7'b1111011;
        4'hA: data_out = 7'b1110111;
        4'hB: data_out = 7'b0011111;
        4'hC: data_out = 7'b1001110;
        4'hD: data_out = 7'b0111101;
        4'hE: data_out = 7'b1001111;
        4'hF: data_out = 7'b1000111;
      endcase
   end
        
endmodule