//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.9 Beta-3
//Part Number: GW1NSR-LV4CQN48PC6/I5
//Device: GW1NSR-4C
//Created Time: Fri Oct 06 21:46:03 2023

module Gowin_SDPB_32 (dout, clka, cea, reseta, clkb, ceb, resetb, oce, ada, din, adb);

output [31:0] dout;
input clka;
input cea;
input reseta;
input clkb;
input ceb;
input resetb;
input oce;
input [4:0] ada;
input [31:0] din;
input [4:0] adb;

wire gw_vcc;
wire gw_gnd;

assign gw_vcc = 1'b1;
assign gw_gnd = 1'b0;

SDPB sdpb_inst_0 (
    .DO(dout[31:0]),
    .CLKA(clka),
    .CEA(cea),
    .RESETA(reseta),
    .CLKB(clkb),
    .CEB(ceb),
    .RESETB(resetb),
    .OCE(oce),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,ada[4:0],gw_gnd,gw_vcc,gw_vcc,gw_vcc,gw_vcc}),
    .DI(din[31:0]),
    .ADB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,adb[4:0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam sdpb_inst_0.READ_MODE = 1'b0;
defparam sdpb_inst_0.BIT_WIDTH_0 = 32;
defparam sdpb_inst_0.BIT_WIDTH_1 = 32;
defparam sdpb_inst_0.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_0.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_0.RESET_MODE = "SYNC";

endmodule //Gowin_SDPB_32
