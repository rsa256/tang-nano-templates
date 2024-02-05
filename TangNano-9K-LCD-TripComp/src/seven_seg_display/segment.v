module segment #(parameter w = 8, parameter h = 56) (x, y, pix_out); 
   input [8:0] x;
   input [8:0] y;
   output pix_out;

   assign pix_out = y < w/2 ? (x >= (w/2 - y) && x < (w/2 + y)) : y < h-w/2 ? (x < w) : y < h ? (x >= (w/2 + y - h) && x < (w/2 - y + h)) : 1'b0; 

endmodule
