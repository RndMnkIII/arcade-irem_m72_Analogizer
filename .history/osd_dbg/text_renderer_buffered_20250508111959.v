module text_renderer_buffered(
    input clk,
    input pixel_ce,
    input [9:0] hpos,
    input [9:0] vpos,
    output reg show_pixel,
    output [6:0] rd_addr,
    input [7:0] rd_char
);
    // División en celdas de 8x8
    wire [3:0] col = hpos[6:3];  // columna 0–15
    wire [2:0] row = vpos[6:3];  // fila 0–7
    wire [2:0] y_offset = vpos[2:0];
    wire [2:0] x_offset = hpos[2:0];

    // Dirección lineal del carácter en el buffer de texto
    assign rd_addr = row * 16 + col;

    // Bitmap del carácter
    wire [7:0] pixels;
    font_rom font(.char(rd_char[6:0]), .row(y_offset), .pixels(pixels));

    always @(posedge clk) begin
        if (pixel_ce) begin
            if (hpos < 128 && vpos < 64)
                show_pixel <= pixels[7 - x_offset];
            else
                show_pixel <= 0;
        end
    end
endmodule
