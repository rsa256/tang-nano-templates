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

    input           uart_rx,
    inout  wire     one_wire,
	output	    	one_gnd
);

    Gowin_rPLL Gowin_rPLL_9Mhz(
        .clkout(LCD_CLK), // 9MHz
        .clkin(XTAL_IN)   //27MHz
    );

    wire [7:0] w_data;
    reg [9:0] w_addr;


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
    parameter ZX_X_START = 24 + 48;
    parameter ZX_X_END = ZX_X_START + ZX_W;
    parameter ZX_Y_START = 0;
    parameter ZX_Y_END = ZX_Y_START + ZX_H;


    wire [8:0] sx = {x - ZX_X_START}[8:0];
    wire [7:0] sy = {y - ZX_Y_START}[7:0];

    parameter ZX_PIXEL_BYTES = ZX_H * ZX_W / 8;
    reg [7:0] ar;
    wire [7:0] ar_read;

    parameter ZX_ATTR_BYTES = ZX_PIXEL_BYTES / 8;
    wire [9:0] attr_addr = { sy[7:3], sx[7:3] };
    reg [7:0] sr;

    reg [7:0] tag [0:3];
    reg [5:0] par_cnt;
    reg [5:0] par_i;
    reg [3:0] gtime [0:5];

    parameter TZ_OFFSET = 11;
    wire [9:0] hours_offset = gtime[0] * 10 + gtime[1] + TZ_OFFSET;
    wire [4:0] hours = hours_offset[4:0] >= 5'd24 ? hours_offset[4:0] - 5'd24 : hours_offset[4:0];
    wire [4:0] hh = hours / 10; 
    wire [3:0] hl = hours % 10;

    reg [3:0] gdate [0:5];

    ram_dual ram_dual_inst
    (
        .clk_r(LCD_CLK),
        .addr_r(attr_addr),
        .attr(ar_read),
        .re(re),
        .clk_w(LCD_CLK),
        .addr_w(w_addr),
        .d(w_data),
        .we(rxDone && (par_cnt > 0))
    );

    wire [7:0] info_out;
    wire [15:0] info_color = info_out[~x[2:0]] ? 16'hFFFF : 16'h3A34;

    wire [15:0] border_color = 16'h0000;

    font font_inst
    (
        .clk(LCD_CLK),
        .line(sy[2:0]),
        .char(ar_read[6:0]),
        .re(re),
        .data_out(info_out)
    );

    wire [7:0] date_out;
    wire [15:0] date_color = date_out[~x[3:1]] ? 16'hFFFF : 16'h0000;

    reg [7:0] date_label [0:4];
    initial begin
        date_label[0] = "D";
        date_label[1] = "a";
        date_label[2] = "t";
        date_label[3] = "e";
        date_label[4] = ":";
    end


    wire [15:0] t_buf;
    reg [7:0] temp_label [0:4];
    initial begin
        temp_label[0] = "T";
        temp_label[1] = "e";
        temp_label[2] = "m";
        temp_label[3] = "p";
        temp_label[4] = ":";
    end

    wire [3:0] temp_bcd = (x[5:4] == 0 ? t_buf[11:8] : x[5:4] == 1 ? t_buf[7:4] : t_buf[3:0]);
    wire [7:0] temp_read = y[4] == 0 ? temp_label[x[6:4]] : x[6:4] >=4 ? " " : x[6:4] == 2 ? "." : (temp_bcd <= 9) ? temp_bcd + "0" : temp_bcd + ("A" - 10);

    wire [7:0] date_read = y[4] == 0 ? date_label[x[6:4]] : !time_valid ? " " : gdate[x[6:4]] + "0";
    wire dre = (vga_re && x[3:0] == 15);

    wire [7:0] info_read = y[7:5] == 0 ? temp_read : date_read;

    font font_date
    (
        .clk(LCD_CLK),
        .line(y[3:1]),
        .char(info_read[6:0]),
        .re(dre),
        .data_out(date_out)
    );

    wire segment_out;
    wire sand_out;

    clock clock_inst
    (
        .x(x),
        .y(y - 9'd80),
        .pix_out(segment_out),
        .sand_out(sand_out),
        .hh(hh[3:0]),
        .hl(hl),
        .mh(gtime[2]),
        .ml(gtime[3]),
        .sh(gtime[4]),
        .sl(gtime[5]),
        .dots_on(par_cnt>0)
    );


    reg [31:0] sec_cnt;
    reg [31:0] gps_timeout;
    reg time_valid = 1'b0;
    wire [15:0] clock_color = time_valid ? 16'b0000011111100000 : 16'b1111100000000000;

    function [3:0] trunc_8_to_4(input [7:0] val);
      trunc_8_to_4 = val[3:0];
    endfunction


    always @(posedge LCD_CLK) begin
        
        if (re) begin
            ar <= ar_read;
        end

        // Info rendering
        if (x >= 16 && x < 16 + 16*6 && y >=0 && y < 64) begin
            vga_datain <= date_color;
        end else

        // Clock rendering
        if (y > 80) begin
            vga_datain <= sand_out ? 16'b1111111111100000 : (segment_out ? clock_color : 16'h0000);
        end else
        
        // Info Rendering
        if (x >= ZX_X_START + 16 && x < ZX_X_END + 16 && y >= ZX_Y_START && y < ZX_Y_END + 4*8) begin
            vga_datain <= info_color;
        end else
        if (x == 0 || x == 340 || y == 0 || y == 199) begin
            vga_datain <= 16'hffff;
        end else
            
        // Border rendering
        vga_datain <= border_color;

        if (rxDone) begin
            for (int i=0; i<=2; i++) begin
                tag[i] <= tag[i+1];
            end
            tag[3] <= w_data;

            if (tag[1] == "R" && tag[2] == "M" && tag[3] == "C") begin
                par_cnt <= 1;
                par_i <= 0;
                w_addr <= 0;
            end

            if (par_cnt > 0) begin
                if (w_data == "*") begin
                    par_cnt <= 0;
                end else if (w_data == ",") begin
                    par_cnt <= par_cnt + 1'b1;
                    par_i <= 0;
                    w_addr <= (w_addr & 10'b1111100000) + 10'b0000100000;
                end else begin
                    if (par_cnt == 1) begin
                        gtime[par_i] <= trunc_8_to_4(w_data - "0");
                        if (par_i == 5) begin
                            time_valid <= 1'b1;
                            gps_timeout <= 0;
                        end
                    end else
                    if (par_cnt == 9) begin
                        gdate[par_i] <= trunc_8_to_4(w_data - "0");
                    end
                    par_i <= par_i + 1'b1;
                    w_addr <= w_addr + 1'b1;
                end
            end

            /*
            if (w_data == 8'h0a) begin
                w_addr <= (w_addr & 10'b1111100000) + 10'b0000100000;
            end else begin
                w_addr <= w_addr + 1'b1;
            end
            */
        end

        sec_cnt <= sec_cnt + 1'b1;
        if (sec_cnt == P_CLK - 1) begin
            sec_cnt <= 1'b0;
            gps_timeout <= gps_timeout + 1'b1;
            if (gps_timeout >= 1) begin
                // Continue clock update with seconds counter
                gtime[5] <= gtime[5] + 1'b1;
                if (gtime[5] >= 9) begin
                    gtime[5] <= 0;
                    gtime[4] <= gtime[4] + 1'b1;
                    if (gtime[4] >= 5) begin
                        gtime[4] <= 0;
                        gtime[3] <= gtime[3] + 1'b1;
                        if (gtime[3] >= 9) begin
                            gtime[3] <= 0;
                            gtime[2] <= gtime[2] + 1'b1;
                            if (gtime[2] >= 5) begin
                                gtime[2] <= 0;
                                gtime[1] <= gtime[1] + 1'b1;
                                if (gtime[1] >= 9) begin
                                    gtime[1] <= 0;
                                    gtime[0] <= gtime[0] + 1'b1;
                                    if (gtime[0] >= 2) begin
                                        gtime[5] <= 0;
                                    end
                                end else 
                                if (gtime[0] == 2 && gtime[1] == 3) begin
                                    gtime[1] <= 0;
                                    gtime[0] <= 0;
                                end
                            end
                        end
                    end
                end
            end
        end

    end

localparam UART_BAUD_RATE = 9600;
localparam F_CLKIN = 27000000;
localparam PLL_IDIV  = 2; // 0~63
localparam PLL_FBDIV = 3; // 0~63
localparam PLL_ODIV  = 32; // 2, 4, 8, 16, 32, 48, 64, 80, 96, 112, 128
localparam P_CLK = F_CLKIN * (PLL_FBDIV+1) / (PLL_IDIV+1);

wire [15:0] clk_per_bit = P_CLK / UART_BAUD_RATE;


UART_RX UART_RX_instance(
    .i_Clock(LCD_CLK),
    .i_Clks_Per_Bit(clk_per_bit),
    .i_RX_Serial(uart_rx),
    .o_RX_Byte(w_data),
    .o_RX_DV(rxDone)
);

assign one_gnd = 1'b0;

ds18b20_drive ds18b20_u0(
  .clk(XTAL_IN),
  .rst_n(Reset_Button),
  .one_wire(one_wire),
  .temperature(t_buf)
);


endmodule