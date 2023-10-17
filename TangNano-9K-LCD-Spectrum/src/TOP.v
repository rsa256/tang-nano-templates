module TOP
(
	input			Reset_Button,
    input           XTAL_IN,

	output			LCD_CLK,
	output			LCD_HYNC,
	output			LCD_SYNC,
	output			LCD_DEN,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B,

	//SPI
	input spi_clk,
	input spi_dat,
	input spi_cs,

	// vsync
 	output vsyncx
);

    Gowin_rPLL Gowin_rPLL_9Mhz(
        .clkout(LCD_CLK), // 9MHz
        .clkin(XTAL_IN)   //27MHz
    );


    // SPI Data interface
    reg [6:0] spi_reg;
    wire [7:0] spi_in = {spi_reg[6:0], spi_dat};
    reg [2:0] spi_bit;
    reg [12:0] spi_cnt;
    reg [7:0] spi_data;

    always @(posedge spi_clk or posedge spi_cs) begin
        if (spi_cs) begin
            spi_cnt <= ZX_PIXEL_BYTES + ZX_ATTR_BYTES + INFO_BYTES - 1;
            spi_bit <= 0;
        end else begin
            spi_bit <= spi_bit + 3'b1;
            spi_reg <= spi_in[6:0];
            if (spi_bit == 3'b111) begin
                spi_data <= spi_in;
                // Registers
                if (spi_cnt == 13'h1b80) begin
                    b <= spi_data[2:0];
                end    
                if (spi_cnt == ZX_PIXEL_BYTES + ZX_ATTR_BYTES + INFO_BYTES - 1)
                    spi_cnt <= 0;
                else
                    spi_cnt <= spi_cnt + 12'b1;
            end
        end
    end

    parameter HDISP = 12'd1024/3;
    parameter VDISP = 12'd600/3;
    reg [15:0] vga_datain = 0;
    wire [8:0] x;
    wire [7:0] y;
    wire vga_re;
    

	VGA_timing	VGA_timing_inst(
		.PixelClk	(	LCD_CLK		),
		.nRST		(	Reset_Button),

		.LCD_DE		(	LCD_DEN	 	),
		.LCD_HSYNC	(	LCD_HYNC 	),
    	.LCD_VSYNC	(	LCD_SYNC 	),

		.LCD_B		(	LCD_B		),
		.LCD_G		(	LCD_G		),
		.LCD_R		(	LCD_R		),
        .LCD_X      (   x           ),
        .LCD_Y      (   y           ),
        .vga_re     (   vga_re          ),
        .vga_datain (   vga_datain  )
	);

    assign vsyncx = LCD_SYNC;
    wire re = (vga_re && x[2:0] == 7);

    // ZX screen
    parameter ZX_W = 256;
    parameter ZX_H = 192;
    parameter ZX_X_START = 24;
    parameter ZX_X_END = ZX_X_START + ZX_W;
    parameter ZX_Y_START = 0;
    parameter ZX_Y_END = ZX_Y_START + ZX_H;

    reg [2:0] b = 3'b111;
    wire [15:0] border_color = { b[1], 4'b0000, b[2], 5'b00000, b[0], 4'b0000 };

    wire [8:0] sx = {x - ZX_X_START}[8:0];
    wire [7:0] sy = {y - ZX_Y_START}[7:0];

    parameter ZX_PIXEL_BYTES = ZX_H * ZX_W / 8;
    wire [12:0] pix_addr = { sy[7:6], sy[2:0], sy[5:3], sx[7:3] };
    reg [7:0] ar;
    wire [7:0] ar_read;

    parameter ZX_ATTR_BYTES = ZX_PIXEL_BYTES / 8;
    wire [9:0] attr_addr = { sy[7:3], sx[7:3] };
    reg [7:0] sr;
    wire [7:0] sr_read;

    parameter INFO_BYTES = 256;

    reg [4:0] flash_cnt = 0;
    wire inv = ar[7] && flash_cnt[4];

    wire ir = ar[1] && ar[6];
    wire ig = ar[2] && ar[6];
    wire ib = ar[0] && ar[6];
    wire pr = ar[4] && ar[6];
    wire pg = ar[5] && ar[6];
    wire pb = ar[3] && ar[6];

    wire [15:0] inc_color = { ar[1], ir, ir, ir, ir, ar[2], ig, ig, ig, ig, ig, ar[0], ib, ib, ib, ib };
    wire [15:0] paper_color = { ar[4], pr, pr, pr, pr, ar[5], pg, pg, pg, pg, pg, ar[3], pb, pb, pb, pb };
    wire [15:0] screen_color = (sr[~x[2:0]] ^ inv) ? inc_color : paper_color;

    ram_dual ram_dual_inst
    (
        .clk_r(LCD_CLK),
        .addr_r(pix_addr),
        .pix(sr_read),
        .attr(ar_read),
        .re(re),
        .clk_w(spi_clk),
        .addr_w(spi_cnt),
        .d(spi_data),
        .we(spi_bit == 3'b111)
    );

    wire [7:0] info_out;
    wire [15:0] info_color = info_out[~x[2:0]] ? 16'h0 : 16'h3A34;

    font font_inst
    (
        .clk(LCD_CLK),
        .line(sy[2:0]),
        .char(ar_read[6:0]),
        .re(re),
        .data_out(info_out)
    );

    always @(posedge LCD_CLK) begin

        if (y == 0) begin
            flash_cnt <= flash_cnt + 5'b1;
        end
        
        if (re) begin
            ar <= ar_read;
            sr <= sr_read;
        end

        
        // Screen Rendering
        if (x >= ZX_X_START + 16 && x < ZX_X_END + 16 && y >= ZX_Y_START && y < ZX_Y_END) begin
            vga_datain <= screen_color;
        end else
        
        // Info Rendering
        if (x >= ZX_X_START + 16 && x < ZX_X_END + 16 && y >= ZX_Y_END && y < ZX_Y_END + 4*8) begin
            vga_datain <= info_color;
        end else
        if (x == 0 || x == 340 || y == 0 || y == 199) begin
            vga_datain <= 16'hffff;
        end else
            
        
        // Border rendering
        vga_datain <= border_color;

    end


endmodule