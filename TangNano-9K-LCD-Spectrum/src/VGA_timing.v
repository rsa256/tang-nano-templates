module VGA_timing
(
    input                   PixelClk,
    input                   nRST,

    output                  LCD_DE,
    output                  LCD_HSYNC,
    output                  LCD_VSYNC,

	output          [4:0]   LCD_B,
	output          [5:0]   LCD_G,
	output          [4:0]   LCD_R,

	//export
	output          [8:0]   LCD_X,
	output          [7:0]   LCD_Y,
	output                  vga_re,
	input           [15:0] 	vga_datain
);
	
    // Horizen count to Hsync, then next Horizen line.

    parameter       H_Pixel_Valid    = 9'd342; // 1024
    parameter       H_FrontPorch     = 9'd42; //128
    parameter       H_BackPorch      = 9'd0;  

    parameter       PixelForHS       = H_Pixel_Valid + H_FrontPorch + H_BackPorch;

    parameter       V_Pixel_Valid    = 8'd200; // 600 
    parameter       V_FrontPorch     = 8'd8;   // 24
    parameter       V_BackPorch      = 8'd0;    

    parameter       PixelForVS       = V_Pixel_Valid + V_FrontPorch + V_BackPorch;

    // Horizen pixel count

    reg         [1:0]  H_DotCount;
    reg         [1:0]  V_DotCount;
    reg         [8:0]  H_PixelCount;
    reg         [7:0]  V_PixelCount;

    always @(  posedge PixelClk or negedge nRST  )begin
        if( !nRST ) begin
            V_PixelCount      <=  8'b0;    
            H_PixelCount      <=  9'b0;
            V_DotCount        <=  2'b0;
            H_DotCount        <=  2'b0;
        end else if(  H_PixelCount == PixelForHS ) begin
            H_PixelCount      <=  9'b0;
            if (  V_DotCount == 2 ) begin
                V_DotCount        <=  2'b0;
                V_PixelCount      <=  V_PixelCount + 1'b1;
            end else begin
                V_DotCount      <=  V_DotCount + 1'b1;
            end
        end else if(  V_PixelCount == PixelForVS ) begin
            V_PixelCount      <=  8'b0;
            H_PixelCount      <=  9'b0;
        end else begin
            if (  H_DotCount == 2 ) begin
                H_DotCount        <=  2'b0;
                V_PixelCount      <=  V_PixelCount;
                H_PixelCount      <=  H_PixelCount + 1'b1;
            end else begin
                H_DotCount      <=  H_DotCount + 1'b1;
            end
        end
    end

    // SYNC-DE MODE
    
    assign  LCD_HSYNC = H_PixelCount <= (PixelForHS-H_FrontPorch) ? 1'b0 : 1'b1;
    
	assign  LCD_VSYNC = V_PixelCount  <= (PixelForVS-V_FrontPorch)  ? 1'b0 : 1'b1;

    assign  LCD_DE =    ( H_PixelCount >= H_BackPorch ) && ( H_PixelCount <= H_Pixel_Valid + H_BackPorch ) &&
                        ( V_PixelCount >= V_BackPorch ) && ( V_PixelCount <= V_Pixel_Valid + V_BackPorch ) && PixelClk;

    assign  LCD_X = H_PixelCount;
    assign  LCD_Y = V_PixelCount;
    assign  vga_re = (H_DotCount == 2);


    assign  LCD_R     =  vga_datain[15:11];
    assign  LCD_G     =  vga_datain[10:5];
    assign  LCD_B     =  vga_datain[4:0];

endmodule
