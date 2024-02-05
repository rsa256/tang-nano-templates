module display #(parameter w = 12, parameter h = 52) (x, y, pix_out, seg_data);
    input [8:0] x;
    input [8:0] y;
    output pix_out;
    input [6:0] seg_data;

    wire [8:0] offset_hor_0 = w/2;
    wire [8:0] offset_hor_1 = h + w/2 + 1;
    wire [8:0] offset_ver_1 = h + 1;

    segment #(.w(w), .h(h)) segment_a
    (
        .x(y),
        .y(x - offset_hor_0),
        .pix_out(a_out)
    );

    segment #(.w(w), .h(h)) segment_b
    (
        .x(x - offset_ver_1),
        .y(y - offset_hor_0),
        .pix_out(b_out)
    );

    segment #(.w(w), .h(h)) segment_c
    (
        .x(x - offset_ver_1),
        .y(y - offset_hor_1),
        .pix_out(c_out)
    );

    segment #(.w(w), .h(h)) segment_d
    (
        .x(y - offset_ver_1 - offset_ver_1),
        .y(x - offset_hor_0),
        .pix_out(d_out)
    );

    segment #(.w(w), .h(h)) segment_e
    (
        .x(x),
        .y(y - offset_hor_1),
        .pix_out(e_out)
    );

    segment #(.w(w), .h(h)) segment_f
    (
        .x(x),
        .y(y - offset_hor_0),
        .pix_out(f_out)
    );

    segment #(.w(w), .h(h)) segment_g
    (
        .x(y - offset_ver_1),
        .y(x - offset_hor_0),
        .pix_out(g_out)
    );


    assign pix_out = (a_out & seg_data[6]) || (b_out & seg_data[5]) || (c_out & seg_data[4]) || (d_out & seg_data[3]) || (e_out & seg_data[2]) || (f_out & seg_data[1]) || (g_out & seg_data[0]);

endmodule