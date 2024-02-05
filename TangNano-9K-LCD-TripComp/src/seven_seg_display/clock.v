module clock  #(parameter w = 12, parameter h = 52, parameter digit_gap = 8, parameter screen_w = 341)
(x, y, pix_out, sand_out, hh, hl, mh, ml, sh, sl, dots_on);
    input [8:0] x;
    input [8:0] y;
    output pix_out;
    output sand_out;
    input [3:0] hh;
    input [3:0] hl;
    input [3:0] mh;
    input [3:0] ml;
    input [3:0] sh;
    input [3:0] sl;
    input dots_on;

    wire [8:0] offset_digit = (h + w + digit_gap);
    wire [8:0] offset_mintes = (screen_w - 2*(h + w) - digit_gap);
    wire [8:0] sand_center = (screen_w/2);

    wire [6:0] din_hh;
    segfont segfont_hh
    (
        .digit(hh),
        .data_out(din_hh)
    );
    display #(.w(w), .h(h)) display_hh
    (
        .x(x),
        .y(y),
        .pix_out(dout_hh),
        .seg_data(din_hh)
    );

    wire [6:0] din_hl;
    segfont segfont_hl
    (
        .digit(hl),
        .data_out(din_hl)
    );
    display #(.w(w), .h(h)) display_hl
    (
        .x(x - offset_digit),
        .y(y),
        .pix_out(dout_hl),
        .seg_data(din_hl)
    );

    wire [6:0] din_mh;
    segfont segfont_mh
    (
        .digit(mh),
        .data_out(din_mh)
    );
    display #(.w(w), .h(h)) display_mh
    (
        .x(x - offset_mintes),
        .y(y),
        .pix_out(dout_mh),
        .seg_data(din_mh)
    );

    wire [6:0] din_ml;
    segfont segfont_ml
    (
        .digit(ml),
        .data_out(din_ml)
    );
    display #(.w(w), .h(h)) display_ml
    (
        .x(x - (offset_mintes + offset_digit)),
        .y(y),
        .pix_out(dout_ml),
        .seg_data(din_ml)
    );

    function [11:0] trunc_32_to_7(input [31:0] val32);
      trunc_32_to_7 = val32[6:0];
    endfunction


    wire dots;
    assign dots = dots_on && x >= 152 && x < 168 && ((y >= 32 && y < 48) || (y >= 64 && y < 80));

    wire [6:0] secs = trunc_32_to_7(sh * 10 + sl);
    wire [6:0] sand_w_top = trunc_32_to_7((60 - y) >> 1);
    wire [6:0] sand_w_bot = trunc_32_to_7((y - 60) >> 1);

    wire sand_top = x >= sand_center - sand_w_top && x < sand_center + sand_w_top && y <= 60 && y >= secs;
    wire sand_bot = x >= sand_center - sand_w_bot && x < sand_center + sand_w_bot && y >=60 && y < 120 && y >= 120 - secs;
    wire sand_stream = x >= (sand_center - 6'd1) && x <= sand_center && y >=59 && y <= 120 && y[0] == 0 && dots_on;

    wire sand_out = sand_top || sand_bot || sand_stream;
   
    assign pix_out = dout_hh || dout_hl || dout_mh || dout_ml;

endmodule