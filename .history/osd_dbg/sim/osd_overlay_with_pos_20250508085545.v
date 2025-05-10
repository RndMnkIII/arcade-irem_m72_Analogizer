
module osd_overlay_with_pos(
    input clk,
    input pixel_ce,
    input [7:0] debug_value,
    input [7:0] RGB_in_R, RGB_in_G, RGB_in_B,
    input HS, VS,
    input HBLANK, VBLANK,
    output [7:0] RGB_out_R, RGB_out_G, RGB_out_B,
    output HS_out, VS_out
);
    wire [9:0] hpos, vpos;
    wire [7:0] ascii_hi, ascii_lo;
    wire show;

    pixel_position_counter pos_counter (
        .clk(clk),
        .pixel_ce(pixel_ce),
        .HS(HS),
        .VS(VS),
        .hpos(hpos),
        .vpos(vpos)
    );

    ascii_hex_converter conv(
        .value(debug_value),
        .ascii_hi(ascii_hi),
        .ascii_lo(ascii_lo)
    );

    text_renderer text(
        .clk(clk),
        .pixel_ce(pixel_ce),
        .hpos(hpos),
        .vpos(vpos),
        .char0(ascii_hi),
        .char1(ascii_lo),
        .show_pixel(show)
    );

    assign RGB_out_R = (HBLANK || VBLANK) ? 8'd0 : (show ? 8'hFF : RGB_in_R);
    assign RGB_out_G = (HBLANK || VBLANK) ? 8'd0 : (show ? 8'hFF : RGB_in_G);
    assign RGB_out_B = (HBLANK || VBLANK) ? 8'd0 : (show ? 8'hFF : RGB_in_B);

    assign HS_out = HS;
    assign VS_out = VS;
endmodule
