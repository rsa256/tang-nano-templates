module top (
    input  wire       rst_n,
    input  wire       clk,
    output wire       hdmi_clk_p,
    output wire       hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,
    input  wire       uart_rx,
    inout  [15:0]     gpio_io
);

localparam UART_BAUD_RATE = 115200;

// f_CLKOUT = f_CLKIN * FBDIV / IDIV, 3.125~600MHz
// f_VCO = f_CLKOUT * ODIV, 400~1200MHz
// f_PFD = f_CLKIN / IDIV = f_CLKOUT / FBDIV, 3~400MHz

localparam F_CLKIN = 27000000;
localparam PLL_IDIV  =  2 - 1; // 0~63
localparam PLL_FBDIV = 35 - 1; // 0~63: 46 - 1080p 35 - 720p(75hz)
localparam PLL_ODIV  =      2; // 2, 4, 8, 16, 32, 48, 64, 80, 96, 112, 128
localparam P_CLK = F_CLKIN * (PLL_FBDIV+1) / (PLL_IDIV+1) / 5;

// 720p
localparam DVI_H_BPORCH = 12'd220;
localparam DVI_H_ACTIVE = 12'd1280;
localparam DVI_H_FPORCH = 12'd110;
localparam DVI_H_SYNC   = 12'd40;
localparam DVI_H_POLAR  = 1'b1;
localparam DVI_V_BPORCH = 12'd20;
localparam DVI_V_ACTIVE = 12'd720;
localparam DVI_V_FPORCH = 12'd5;
localparam DVI_V_SYNC   = 12'd5;
localparam DVI_V_POLAR  = 1'b1;

// 1080p
/*
localparam DVI_H_BPORCH = 12'd148;
localparam DVI_H_ACTIVE = 12'd1920;
localparam DVI_H_FPORCH = 12'd88;
localparam DVI_H_SYNC   = 12'd44;
localparam DVI_H_POLAR  = 1'b1;
localparam DVI_V_BPORCH = 12'd36;
localparam DVI_V_ACTIVE = 12'd1080;
localparam DVI_V_FPORCH = 12'd4;
localparam DVI_V_SYNC   = 12'd5;
localparam DVI_V_POLAR  = 1'b1;
*/

// 1440p
/*
localparam DVI_H_BPORCH = 12'd40;
localparam DVI_H_ACTIVE = 12'd2560;
localparam DVI_H_FPORCH = 12'd8;
localparam DVI_H_SYNC   = 12'd32;
localparam DVI_H_POLAR  = 1'b1;
localparam DVI_V_BPORCH = 12'd6;
localparam DVI_V_ACTIVE = 12'd1440;
localparam DVI_V_FPORCH = 12'd13;
localparam DVI_V_SYNC   = 12'd8;
localparam DVI_V_POLAR  = 1'b0;
*/

//localparam DVI_H_BPORCH = 12'd80;
//localparam DVI_H_ACTIVE = 12'd2560;
//localparam DVI_H_FPORCH = 12'd48;
//localparam DVI_H_SYNC   = 12'd32;
//localparam DVI_H_POLAR  = 1'b1;
//localparam DVI_V_BPORCH = 12'd33;
//localparam DVI_V_ACTIVE = 12'd1440;
//localparam DVI_V_FPORCH = 12'd3;
//localparam DVI_V_SYNC   = 12'd5;
//localparam DVI_V_POLAR  = 1'b0;

wire rst;
wire clk_serial;
wire clk_pixel;
wire pll_locked;

reg       rgb_vs;
reg       rgb_hs;
reg       rgb_de;
reg [7:0] rgb_r;
reg [7:0] rgb_g;
reg [7:0] rgb_b;

assign rst = ~rst_n;

PLLVR #(
    .FCLKIN    (27),
    .IDIV_SEL  (PLL_IDIV),
    .FBDIV_SEL (PLL_FBDIV),
    .ODIV_SEL  (PLL_ODIV),
    .DEVICE    ("GW1NSR-4C")
) pll (
    .CLKIN    (clk),
    .CLKFB    (1'b0),
    .RESET    (rst),
    .RESET_P  (1'b0),
    .FBDSEL   (6'b0),
    .IDSEL    (6'b0),
    .ODSEL    (6'b0),
    .DUTYDA   (4'b0),
    .PSDA     (4'b0),
    .FDLY     (4'b0),
    .VREN     (1'b1),
    .CLKOUT   (clk_serial),
    .LOCK     (pll_locked),
    .CLKOUTP  (),
    .CLKOUTD  (),
    .CLKOUTD3 ()
);

CLKDIV #(
    .DIV_MODE (5)
) clk_pixel_gen (
    .HCLKIN (clk_serial),
    .RESETN (rst_n),
    .CALIB  (1'b0),
    .CLKOUT (clk_pixel)
);

DVI_TX_Top dvi_tx (
    .I_rst_n       (rst_n),       // input I_rst_n
    .I_serial_clk  (clk_serial),  // input I_serial_clk
    .I_rgb_clk     (clk_pixel),   // input I_rgb_clk
    .I_rgb_vs      (rgb_vs),      // input I_rgb_vs
    .I_rgb_hs      (rgb_hs),      // input I_rgb_hs
    .I_rgb_de      (rgb_de),      // input I_rgb_de
    .I_rgb_r       (rgb_r),       // input [7:0] I_rgb_r
    .I_rgb_g       (rgb_g),       // input [7:0] I_rgb_g
    .I_rgb_b       (rgb_b),       // input [7:0] I_rgb_b
    .O_tmds_clk_p  (hdmi_clk_p),  // output O_tmds_clk_p
    .O_tmds_clk_n  (hdmi_clk_n),  // output O_tmds_clk_n
    .O_tmds_data_p (hdmi_data_p), // output [2:0] O_tmds_data_p
    .O_tmds_data_n (hdmi_data_n)  // output [2:0] O_tmds_data_n
);

// Video Timing Generator

reg [11:0] cnt_h;
reg [11:0] cnt_h_next;
reg [11:0] cnt_v;
reg [11:0] cnt_v_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        cnt_h <= 12'd0;
        cnt_v <= 12'd0;
    end else if (!pll_locked) begin
        cnt_h <= 12'd0;
        cnt_v <= 12'd0;
    end else begin
        cnt_h <= cnt_h_next;
        cnt_v <= cnt_v_next;
    end

always @(*) begin
    if (cnt_h == DVI_H_BPORCH + DVI_H_ACTIVE + DVI_H_FPORCH + DVI_H_SYNC - 1'd1) begin
        cnt_h_next = 12'd0;
        if (cnt_v == DVI_V_BPORCH + DVI_V_ACTIVE + DVI_V_FPORCH + DVI_V_SYNC - 1'd1) begin
            cnt_v_next = 12'd0;
        end else begin
            cnt_v_next = cnt_v + 1'd1;
        end
    end else begin
        cnt_h_next = cnt_h + 1'd1;
        cnt_v_next = cnt_v;
    end
end

always @(*) begin
    if (cnt_h < DVI_H_BPORCH + DVI_H_ACTIVE + DVI_H_FPORCH) begin
        rgb_hs = ~DVI_H_POLAR;
    end else begin
        rgb_hs = DVI_H_POLAR;
    end

    if (cnt_v < DVI_V_BPORCH + DVI_V_ACTIVE + DVI_V_FPORCH) begin
        rgb_vs = ~DVI_V_POLAR;
    end else begin
        rgb_vs = DVI_V_POLAR;
    end

    if (cnt_h < DVI_H_BPORCH || cnt_h >= DVI_H_BPORCH + DVI_H_ACTIVE) begin
        rgb_de = 1'b0;
    end else if (cnt_v < DVI_V_BPORCH || cnt_v >= DVI_V_BPORCH + DVI_V_ACTIVE) begin
        rgb_de = 1'b0;
    end else begin
        rgb_de = 1'b1;
    end
end

// Video Pattern Generator

reg [23:0] cnt_white;
reg [23:0] cnt_white_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        cnt_white <= 24'd0;
    end else if (cnt_h == 12'd0 && cnt_v == 12'd0) begin
        cnt_white <= cnt_white_next;
    end

always @(*)
    if (cnt_white == DVI_H_ACTIVE * DVI_V_ACTIVE - 1'd1) begin
        cnt_white_next = 24'd0;
    end else begin
        cnt_white_next = cnt_white + 1'd1;
    end

reg [23:0] cnt_de;
reg [23:0] cnt_de_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        cnt_de <= 1'd0;
    end else begin
        cnt_de <= cnt_de_next;
    end

always @(*)
    if (rgb_vs == DVI_V_POLAR) begin
        cnt_de_next = 24'd0;
    end else if (rgb_de) begin
        cnt_de_next = cnt_de + 1'd1;
    end else begin
        cnt_de_next = cnt_de;
    end

wire [23:0] rgb_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        {rgb_r, rgb_g, rgb_b} <= 24'h000000;
    end else begin
        {rgb_r, rgb_g, rgb_b} <= rgb_next;
    end

function [11:0] trunc_32_to_12(input [31:0] val32);
  trunc_32_to_12 = val32[11:0];
endfunction

function [13:0] trunc_32_to_14(input [31:0] val32);
  trunc_32_to_14 = val32[13:0];
endfunction


wire [11:0] x;
wire [11:0] xp;
wire [11:0] y;
assign x = cnt_h - DVI_H_BPORCH;
assign xp = trunc_32_to_12(cnt_h - DVI_H_BPORCH + 8);
assign y = cnt_v - DVI_V_BPORCH;

wire [6:0] char;
wire [7:0] font_out;
wire font_color = font_out[~x[2:0]] ? 1'h1 : 1'h0;

wire [7:0] w_data;
reg [13:0] w_addr;

wire [6:0] hex;
assign hex = (cx == DVI_H_ACTIVE/8 - 4) ? h0 : (cx == DVI_H_ACTIVE/8 - 3) ? h1 : (cx == DVI_H_ACTIVE/8 - 2) ? h2 : (cx == DVI_H_ACTIVE/8 - 1) ? h3 : char;
wire [6:0] charout;
assign charout = (scan_addr == w_addr) ? cursor :(cy == 0) ? hex : !scroll_mode ? char : 7'h00;


font font_inst
(
    .clk(clk_pixel),
    .line(y[2:0]),
    .char(charout),
    .re(x[2:0] == 3'b111),
    .data_out(font_out)
);

reg [15:0] clk_per_bit;
wire [6:0] h0;
assign h0 = clk_per_bit[15:12] + ((clk_per_bit[15:12] < 10) ? 7'h30 : 7'h37);
wire [6:0] h1;
assign h1 = clk_per_bit[11:8] + ((clk_per_bit[11:8] < 10) ? 7'h30 : 7'h37);
wire [6:0] h2;
assign h2 = clk_per_bit[7:4] + ((clk_per_bit[7:4] < 10) ? 7'h30 : 7'h37);
wire [6:0] h3;
assign h3 = clk_per_bit[3:0] + ((clk_per_bit[3:0] < 10) ? 7'h30 : 7'h37);


wire [8:0] cx;
assign cx = xp[11:3];
wire [8:0] cy;
assign cy = y[11:3];

wire [6:0] cursor;
assign cursor = blink ? 7'h7f : 7'h00;
reg [31:0] blink_cnt;
reg blink;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        blink_cnt <= 32'd0;
        blink <= 1'd0;
        clk_per_bit <= P_CLK/UART_BAUD_RATE;
    end else begin
        if (blink_cnt == P_CLK/2) begin
            blink_cnt <= 32'd0;
            blink <= !blink;
        end else begin
            blink_cnt <= blink_cnt + 1;
        end
    end



reg scroll_mode;
reg [13:0] r_addr;
wire [13:0] scan_addr;
assign scan_addr = trunc_32_to_14(y[11:3] * (DVI_H_ACTIVE/8) + xp[11:3]);

wire rxDone;
reg lastRxDone;

Gowin_SDPB char_mem(
    .dout(char), //output [6:0] dout
    .clka(clk_pixel), //input clka
    .cea(scroll_mode ? 1'd1 : rxDone ^ lastRxDone), //input cea
    .reseta(!rst_n), //input reseta
    .clkb(clk_pixel), //input clkb
    .ceb(1'd1), //input ceb
    .resetb(!rst_n), //input resetb
    .oce(1'd1), //input oce
    .ada(w_addr), //input [13:0] ada
    .din(scroll_mode ? (w_addr >= (DVI_H_ACTIVE/8) * (DVI_V_ACTIVE/8 - 1) ? 7'h20 : char) : w_data[6:0]), //input [6:0] din
    .adb(scroll_mode ? r_addr : scan_addr) //input [13:0] adb
);


always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        w_addr <= 14'h000000;
        lastRxDone <= 1'd0;
        scroll_mode <= 1'd0;
    end else begin
        lastRxDone <= rxDone;
        if (w_addr >= (DVI_H_ACTIVE/8) * (DVI_V_ACTIVE/8)) begin
            scroll_mode <= 1;
            w_addr <= 15'h000000;
            r_addr <= (DVI_H_ACTIVE/8);
        end
        if (scroll_mode) begin
            if (w_addr < (DVI_H_ACTIVE/8) * (DVI_V_ACTIVE/8)) begin
                if (r_addr != (DVI_H_ACTIVE/8)) begin
                    w_addr <= w_addr + 1'b1;
                end
                r_addr <= r_addr + 1'b1;
            end else begin
                scroll_mode <= 0;
                w_addr <= (DVI_H_ACTIVE/8) * (DVI_V_ACTIVE/8 - 1);
            end
        end else if (rxDone && !lastRxDone) begin
            case (w_data)
            7'h7f:
                w_addr <= w_addr - 1'b1;
            endcase
        end else if (!rxDone && lastRxDone) begin
            case (w_data)
            7'h0d: 
                w_addr <= trunc_32_to_14((w_addr / (DVI_H_ACTIVE/8)) * (DVI_H_ACTIVE/8));
            7'h0a: 
                w_addr <= trunc_32_to_14(w_addr + (DVI_H_ACTIVE/8));
            7'h7f:
                w_addr <= w_addr;
            7'h09:
                w_addr <= w_addr + 14'd4;
            7'h01:
                w_addr <= 0;
            default:
                w_addr <= w_addr + 1'b1;
            endcase
        end
    end


wire uart_txd_o;

UART_RX UART_RX_instance(
    .i_Clock(clk_pixel),
    .i_Clks_Per_Bit(clk_per_bit),
    .i_RX_Serial(uart_txd_o),
    .o_RX_Byte(w_data),
    .o_RX_DV(rxDone)
);

assign rgb_next = font_color ? 24'h00FF00 : 24'h000000;


Gowin_EMPU_Top MPU(
    .sys_clk   ( clk_pixel  ), //input         sys_clk
    .gpio      ( gpio_io    ), //inout  [15:0] gpio
    .uart0_rxd ( uart_rx    ), //input         uart0_rxd
    .uart0_txd ( uart_txd_o ), //output        uart0_txd
    .reset_n   ( rst_n & pll_locked )  //input         reset_n
);

endmodule
