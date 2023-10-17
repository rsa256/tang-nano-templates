module top (
    input  wire       rst_n,
    input  wire       clk,
    output wire       hdmi_clk_p,
    output wire       hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire       gpioout,

    //HyperRAM Memory Interface
    output     [0:0]  O_hpram_ck      ,
    output     [0:0]  O_hpram_ck_n    ,
    output     [0:0]  O_hpram_cs_n  ,
    output     [0:0]  O_hpram_reset_n ,
    inout      [7:0]  IO_hpram_dq  ,
    inout      [0:0]  IO_hpram_rwds   
);

// f_CLKOUT = f_CLKIN * FBDIV / IDIV, 3.125~600MHz
// f_VCO = f_CLKOUT * ODIV, 400~1200MHz
// f_PFD = f_CLKIN / IDIV = f_CLKOUT / FBDIV, 3~400MHz

localparam F_CLKIN = 27000000;
localparam PLL_IDIV  =  2 - 1; // 0~63
localparam PLL_FBDIV = 34 - 1; // 0~63: 55 - 1080p(60) 46 - 720p
localparam PLL_ODIV  =      2; // 2, 4, 8, 16, 32, 48, 64, 80, 96, 112, 128
localparam P_CLK = F_CLKIN * (PLL_FBDIV+1) / (PLL_IDIV+1) / 5;

// 720p
/*
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
*/

// 1080p
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

wire [15:0] rgb_next;

wire        master_pclk;
wire        master_prst;
wire        master_penable;
wire [7:0]  master_paddr;
wire        master_pwrite;
wire [31:0] master_pwdata;
wire [3:0]  master_pstrb;
wire [2:0]  master_pprot;
wire        master_psel1;
wire [31:0] master_prdata1;
wire        master_pready1;
wire        psel_valid_es1;
wire        penable_valid_es1;


always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        {rgb_r, rgb_g, rgb_b} <= 24'h000000;
    end else begin
        {rgb_r, rgb_g, rgb_b} <= {rgb_next[15:11], 3'd0, rgb_next[10:5], 2'd0, rgb_next[4:0], 3'd0 };
    end

wire [14:0] gpioout_o;
wire [15:0] gpioouten_o;

Gowin_EMPU_Top MPU(
    .sys_clk   ( clk_pixel     ), //input         sys_clk
    .gpioin(16'b0), //input [15:0] gpioin
    .gpioout({gpioout_o, gpioout}), //output [15:0] gpioout
    .gpioouten(gpioouten_o), //output [15:0] gpioouten
    .uart0_rxd ( uart_rx    ), //input         uart0_rxd
    .uart0_txd ( uart_tx    ), //output        uart0_txd
    .master_pclk(master_pclk), //output master_pclk
    .master_prst(master_prst), //output master_prst
    .master_penable(master_penable), //output master_penable
    .master_paddr(master_paddr), //output [7:0] master_paddr
    .master_pwrite(master_pwrite), //output master_pwrite
    .master_pwdata(master_pwdata), //output [31:0] master_pwdata
    .master_pstrb(master_pstrb), //output [3:0] master_pstrb
    .master_pprot(master_pprot), //output [2:0] master_pprot
    .master_psel1(master_psel1), //output master_psel1
    .master_prdata1(master_prdata1), //input [31:0] master_prdata1
    .master_pready1(1'b1), //input master_pready1
    .master_pslverr1(1'b0), //input master_pslverr1
    .reset_n   ( rst_n & pll_locked  )  //input         reset_n
);


wire write_enable = master_psel1    & master_pwrite    & (!master_penable);
wire read_enable  = master_psel1    & (!master_pwrite) &   master_penable;
wire [11:2] paddr  = {4'b0000,master_paddr[7:2]};

//write Block

reg w_req;
reg w_prog;


always @(posedge master_pclk or negedge master_prst)
begin
    if(~master_prst) begin
        addr_w <= 0;
        w_req <= 1'b0;
        mask_0 <= 0;
        mask_1 <= 0;
    end else begin
        if (write_enable) begin
            case (paddr[11:2])
            10'h20: begin
                addr_w <= master_pwdata[21:0];
                w_req <= 1'b1;
            end
            10'h21: mask_0 <= master_pwdata;
            10'h22: mask_1 <= master_pwdata;
            endcase
        end
        if (w_req == 1'b1) begin
            w_req <= 1'b0; 
        end
    end
end

reg [31:0] prdata_out;
//Read Block
always @(*)
begin
    if (read_enable) begin
        prdata_out = {31'h00000000, w_req2 || w_prog};
    end else begin
        prdata_out  = 32'hFFFFFFFF;
    end
end

reg [4:0] xr;
reg [4:0] xp;

assign master_prdata1 = prdata_out;

wire [31:0] rd_data_o;
wire [31:0] wr_data_i;
wire clk_out_o;

Gowin_SDPB_32 write_buf_instance(
    .dout(wr_data_i), //output [31:0] dout
    .clka(master_pclk), //input clka
    .cea(write_enable && (paddr[7] == 0)), //input cea
    .reseta(!master_prst), //input reseta
    .clkb(clk_out_o), //input clkb
    .ceb(1'b1), //input ceb
    .resetb(!rst_n), //input resetb
    .oce(1'b1), //input oce
    .ada(paddr[6:2]), //input [4:0] ada
    .din(master_pwdata), //input [31:0] din
    .adb(xr) //input [4:0] adb
);


Gowin_PLLVR_297 PLLVR_297_instance(
    .clkout(clk_mem2), //output clkout
    .lock(lock_mem), //output lock
    .clkoutd(clk_mem), //output clkoutd
    .clkin(clk_pixel) //input clkin
);

wire clk_i;

reg [21:0] addr_i;
reg [21:0] addr_w;
reg cmd_i;
reg cmd_en_i;
wire rd_data_valid_o;
wire init_calib_o;

reg [31:0] mask_0;
reg [31:0] mask_1;
reg p0;
reg p1;
wire [3:0] data_mask;
assign data_mask = { p0, p0, p1, p1 };



HyperRAM_Memory_Interface_Top HyperRAM(
    .clk(clk_mem), //input clk
    .memory_clk(clk_mem2), //input memory_clk
    .pll_lock(lock_mem), //input pll_lock
    .rst_n(rst_n), //input rst_n
    .O_hpram_ck(O_hpram_ck), //output [0:0] O_hpram_ck
    .O_hpram_ck_n(O_hpram_ck_n), //output [0:0] O_hpram_ck_n
    .IO_hpram_dq(IO_hpram_dq), //inout [7:0] IO_hpram_dq
    .IO_hpram_rwds(IO_hpram_rwds), //inout [0:0] IO_hpram_rwds
    .O_hpram_cs_n(O_hpram_cs_n), //output [0:0] O_hpram_cs_n
    .O_hpram_reset_n(O_hpram_reset_n), //output [0:0] O_hpram_reset_n
    .wr_data(wr_data_i), //input [31:0] wr_data
    .rd_data(rd_data_o), //output [31:0] rd_data
    .rd_data_valid(rd_data_valid_o), //output rd_data_valid
    .addr(addr_i), //input [21:0] addr
    .cmd(cmd_i), //input cmd
    .cmd_en(cmd_en_i), //input cmd_en
    .init_calib(init_calib_o), //output init_calib
    .clk_out(clk_out_o), //output clk_out
    .data_mask(data_mask) //input [3:0] data_mask
);

function [11:0] trunc_32_to_12(input [31:0] val32);
  trunc_32_to_12 = val32[11:0];
endfunction

wire [11:0] x;
wire [11:0] xs;
wire [11:0] y;

assign x = trunc_32_to_12(cnt_h - DVI_H_BPORCH + 2);
assign y = cnt_v - DVI_V_BPORCH;
assign xs = trunc_32_to_12(cnt_h - DVI_H_BPORCH + 48);

reg rq;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        rq <= 1'd0;
    end else begin
        if (xs[5:0] == 0) begin
            rq <= 1'd1;  
        end else begin
            rq <= 1'd0;  
        end
    end

reg w_req2;

reg w_req_prev;

wire [20:0] addr_y;
assign addr_y = xs + y*DVI_H_ACTIVE;

always @(posedge clk_out_o or negedge rst_n)
	if (~rst_n) begin
		cmd_i <= 1'd0;
		cmd_en_i <= 1'd0;
        ada_i <= 1'd0;
        addr_i <= 22'd0;
        w_prog <= 1'b0;
        w_req2 <= 1'b0;
        w_req_prev <= 1'b0;
        xr <= 0;
        xp <= 0;
        p0 <= 0;
        p1 <= 0;
	end else begin
        xp <= ~xs[4:0];
        xr <= ~xp[4:0] + 5'b1;
        w_req_prev <= w_req;
        p0 <= ~xp[4] ? mask_1[{xp[3:0], 1'b0}] : mask_0[{xp[3:0], 1'b0}];
        p1 <= ~xp[4] ? mask_1[{xp[3:0], 1'b1}] : mask_0[{xp[3:0], 1'b1}];
        if (!w_req2 && w_req && !w_req_prev) begin
            w_req2 <= 1'b1;
        end
        if (rd_data_valid_o) begin
            ada_i <= ada_i + 6'b1;
        end else begin
            if (rq && !cmd_en_i) begin
                if ((xs>DVI_H_ACTIVE || cnt_v < DVI_V_BPORCH || cnt_v >= DVI_V_BPORCH + DVI_V_ACTIVE) && w_req2) begin
                    addr_i <= addr_w;
                    //addr_w <= addr_w + 128;
                    //wr_data_i <= (addr_w < 360*2*DVI_H_ACTIVE) ? 32'hf800f800 : (addr_w < 720*2*DVI_H_ACTIVE) ? 32'h07e007e0 : 32'h001f001f;
                    cmd_i <= 1;
                    w_req2 <= 1'b0;
                    w_prog <= 1'b1;
                end else begin
                    addr_i <= {addr_y, 1'b0};
                    cmd_i <= 0;
                end
                cmd_en_i <= 1'd1;
                ada_i <= {xs[6], 5'd0};
            end else begin
                cmd_en_i <= 1'd0;
            end
            if (w_prog && xs[4:0] == 5'h1f) begin
                w_prog <= 0;
            end
        end
    end


reg [5:0] ada_i;
wire [6:0] adb_i;

assign adb_i = x[6:0];

Gowin_SDPB ram_buf(
    .dout(rgb_next), //output [15:0] dout
    .clka(clk_out_o), //input clka
    .cea(rd_data_valid_o), //input cea
    .reseta(!rst_n), //input reseta
    .clkb(clk_pixel), //input clkb
    .ceb(1'd1), //input ceb
    .resetb(!rst_n), //input resetb
    .oce(1'd1), //input oce
    .ada(ada_i), //input [5:0] ada
    .din(rd_data_o), //input [31:0] din
    .adb(adb_i) //input [6:0] adb
);


endmodule
