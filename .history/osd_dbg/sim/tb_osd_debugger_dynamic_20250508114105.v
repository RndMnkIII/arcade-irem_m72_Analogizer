//Questasim:
//Optimize the design:
//vopt +acc tb_osd_debugger_dynamic -o tb_osd_debugger_dynamic_opt
//Load the design:
//vsim tb_osd_debugger_dynamic_opt
//run -all
`timescale 1ns / 1ps

module tb_osd_debugger_dynamic;

    reg clk = 0;
    reg pixel_ce = 0;
    reg HS = 0;
    reg VS = 0;
    reg HBLANK = 0;
    reg VBLANK = 0;
    reg [7:0] RGB_in_R, RGB_in_G, RGB_in_B;
    wire [7:0] RGB_out_R, RGB_out_G, RGB_out_B;
    wire HS_out, VS_out;

    wire [6:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;

    wire [6:0] rd_addr;
    wire [7:0] rd_data;
    wire show_pixel;

    reg [3:0] hoffset_line = 1;
    reg [4:0] hoffset_col = 8;
    reg [3:0] voffset_line = 2;
    reg [4:0] voffset_col = 8;

    reg [7:0] hoffset_val = 8'h00;
    reg [7:0] voffset_val = 8'h00;

    reg we_hoffset = 0;
    reg we_voffset = 0;

    always #5 clk = ~clk;

    text_buffer txtbuf (
        .clk(clk),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .we(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );

    text_renderer_buffered renderer (
        .clk(clk),
        .pixel_ce(pixel_ce),
        .hpos(hpos),
        .vpos(vpos),
        .rd_addr(rd_addr),
        .rd_char(rd_data),
        .show_pixel(show_pixel)
    );

    ascii_hex_writer writer_hoffset (
        .clk(clk),
        .we(we_hoffset),
        .linea(hoffset_line),
        .columna(hoffset_col),
        .value(hoffset_val),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_en(wr_en)
    );

    ascii_hex_writer writer_voffset (
        .clk(clk),
        .we(we_voffset),
        .linea(voffset_line),
        .columna(voffset_col),
        .value(voffset_val),
        .wr_addr(),
        .wr_data(),
        .wr_en()
    );

    parameter HRES = 640;
    parameter VRES = 480;
    integer hpos = 0, vpos = 0;

    integer f;
    integer frame;

    initial begin
        for (frame = 0; frame < 5; frame = frame + 1) begin
            hoffset_val = frame * 8;
            voffset_val = frame * 16;

            // Escribir hoffset
            we_hoffset = 1;
            @(posedge clk);
            we_hoffset = 0;
            @(posedge clk); @(posedge clk);

            // Escribir voffset
            we_voffset = 1;
            @(posedge clk);
            we_voffset = 0;
            @(posedge clk); @(posedge clk);

            f = $fopen($sformatf("frame_%0d.ppm", frame), "w");
            $fwrite(f, "P3\n%d %d\n255\n", HRES, VRES);

            for (vpos = 0; vpos < VRES; vpos = vpos + 1) begin
                VS = (vpos == 0);
                VBLANK = (vpos >= VRES);
                for (hpos = 0; hpos < HRES; hpos = hpos + 1) begin
                    pixel_ce = 1;
                    HS = (hpos == 0);
                    HBLANK = (hpos >= HRES);

                    if (((hpos / 40) + (vpos / 40)) % 2 == 0) begin
                        RGB_in_R = 160;
                        RGB_in_G = 160;
                        RGB_in_B = 160;
                    end else begin
                        RGB_in_R = 60;
                        RGB_in_G = 60;
                        RGB_in_B = 60;
                    end

                    #1;
                    $fwrite(f, "%0d %0d %0d\n",
                        show_pixel ? 255 : RGB_in_R,
                        show_pixel ? 255 : RGB_in_G,
                        show_pixel ? 255 : RGB_in_B
                    );
                    pixel_ce = 0;
                    #9;
                end
            end

            $fclose(f);
        end
        $finish;
    end

endmodule
