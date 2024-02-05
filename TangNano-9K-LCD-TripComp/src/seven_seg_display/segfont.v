module segfont(digit, data_out);
   input [3:0] digit;
   output reg [6:0] data_out;
 
   always @(digit) begin
      case(digit)
        0: data_out = 7'b1111110;
        1: data_out = 7'b0110000;
        2: data_out = 7'b1101101;
        3: data_out = 7'b1111001;
        4: data_out = 7'b0110011;
        5: data_out = 7'b1011011;
        6: data_out = 7'b1011111;
        7: data_out = 7'b1110000;
        8: data_out = 7'b1111111;
        9: data_out = 7'b1111011;
        default: data_out = 7'd0;
      endcase
   end
        
endmodule