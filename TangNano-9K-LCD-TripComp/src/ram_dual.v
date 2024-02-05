module ram_dual(addr_r, addr_w, attr, re, d, we, clk_r, clk_w);
   output[7:0] attr;
   input [7:0] d;
   input [9:0] addr_r;
   input [9:0] addr_w;
   input re, we, clk_r, clk_w;
 
   reg [7:0] attr;

    att_DPB att_DPB_inst(
        .douta(attr), //output [7:0] douta
        .doutb(), //output [7:0] doutb
        .clka(clk_r), //input clka
        .ocea(1'b0), //input ocea
        .cea(re), //input cea
        .reseta(1'b0), //input reseta
        .wrea(1'b0), //input wrea
        .clkb(clk_w), //input clkb
        .oceb(1'b0), //input oceb
        .ceb(1'b1), //input ceb
        .resetb(1'b0), //input resetb
        .wreb(we), //input wreb
        .ada(addr_r), //input [9:0] ada
        .dina(8'd0), //input [7:0] dina
        .adb(addr_w), //input [9:0] adb
        .dinb(d) //input [7:0] dinb
    );

	        
endmodule
