// Project: OSD Overlay
// File: osd_overlay.sv
// Description: Overlay module for displaying OSD (On-Screen Display) characters
//              on a VGA screen. It uses a character RAM and a font ROM to
//              generate the pixel data for the OSD characters.
// Author: @RndMnkIII
// Date: 2025-05-09
// License: MIT
//
`default_nettype none
module osd_top #(
    parameter int CLK_HZ = 32_000_000,
    parameter int DURATION_SEC = 3,
    parameter int COLS = 48,
    parameter int ROWS = 32,
    parameter int CHAR_RAM_SIZE = COLS * ROWS
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         pixel_ce,
    input  logic [7:0]   R_in,
    input  logic [7:0]   G_in,
    input  logic [7:0]   B_in,
    input  logic         hsync_in,
    input  logic         vsync_in,
    input  logic         hblank,
    input  logic         vblank,
    input  logic         key_left,
    input  logic         key_right,
    input  logic         key_up,
    input  logic         key_down,
    output logic [7:0]   R_out,
    output logic [7:0]   G_out,
    output logic [7:0]   B_out,
    output logic         hsync_out,
    output logic         vsync_out,
    output logic [2:0]   hblank_out,
    output logic [2:0]   vblank_out,
    output logic signed [4:0] h_offset_out,
    output logic signed [4:0] v_offset_out
);

  // RAM de caracteres compartida
  logic [10:0] wr_addr, char_rd_addr;
  logic [7:0]  wr_data, char_code;
  logic        wr_en;

    char_ram_dualport #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(8),
        .INIT_FILE("osd_analogizer_ram.mem")
    ) char_mem_inst (
        .clk(clk),
        .we_a(wr_en),
        .addr_a(wr_addr),
        .data_a(wr_data),
        .addr_b(char_rd_addr),
        .data_b(char_code)
    );

    logic [11:0] x_pix, y_pix;
    logic [11:0] width, height;
    logic        timing_ready;

    video_timing_tracker timing_inst (
        .clk(clk),
        .pixel_ce(pixel_ce),
        .hs(hsync_in),
        .vs(vsync_in),
        .hb(hblank),
        .vb(vblank),
        .x(x_pix),
        .y(y_pix),
        .width(width),
        .height(height),
        .ready(timing_ready)
    );

    logic signed [4:0] h_offset = 0, v_offset = 0;

    typedef enum logic [2:0] {
        IDLE,
        UPDATE_H_0,
        UPDATE_H_1,
        UPDATE_H_2,
        UPDATE_V_0,
        UPDATE_V_1,
        UPDATE_V_2
    } state_t;

    state_t state;
    logic key_event;
    always_comb begin
        key_event = key_left || key_right || key_up || key_down;
    end

    logic [7:0] ascii_sign, ascii_tens, ascii_units;
    logic signed [4:0] val;
    logic [4:0] abs_val;
    always_ff @(posedge clk) begin
        ascii_sign  <= (val < 0) ? 8'h2D : 8'h2B;
        abs_val     <= (val < 0) ? -val : val;
        ascii_tens  <= (abs_val >= 10) ? 8'h31 : 8'h20;
        ascii_units <= 8'h30 + (abs_val % 10);
    end

    localparam int H_POS = COLS + COLS + COLS + COLS + COLS + COLS + 10;
    localparam int V_POS = COLS + COLS + COLS + COLS + COLS + COLS + COLS + 10;

    always_ff @(posedge clk) begin
        if (reset) begin
            h_offset <= $signed(5'sd0);
            v_offset <= $signed(5'sd0);
            state <= IDLE;
            wr_en <= 0;
        end else begin
            wr_en <= 0;
            //if (timing_ready) begin
                if (key_left && (h_offset > -5'sd15)) h_offset <= h_offset + $signed(-5'sd1);
                else if (key_right && (h_offset < 5'sd15)) h_offset <= h_offset + $signed(5'sd1);
                if (key_up && (v_offset > -5'sd15)) v_offset <= v_offset + $signed(-5'sd1);
                else if (key_down && (v_offset < 5'sd15)) v_offset <= v_offset + $signed(5'sd1);

                case (state)
                    IDLE: if (key_event) begin
                        state <= UPDATE_H_0;
                        val   <= h_offset;
                    end
                    UPDATE_H_0: begin
                        wr_addr <= H_POS + 0; wr_data <= ascii_sign; wr_en <= 1;
                        state <= UPDATE_H_1;
                    end
                    UPDATE_H_1: begin
                        wr_addr <= H_POS + 1; wr_data <= ascii_tens; wr_en <= 1;
                        state <= UPDATE_H_2;
                    end
                    UPDATE_H_2: begin
                        wr_addr <= H_POS + 2; wr_data <= ascii_units; wr_en <= 1;
                        val <= v_offset;
                        state <= UPDATE_V_0;
                    end
                    UPDATE_V_0: begin
                        wr_addr <= V_POS + 0; wr_data <= ascii_sign; wr_en <= 1;
                        state <= UPDATE_V_1;
                    end
                    UPDATE_V_1: begin
                        wr_addr <= V_POS + 1; wr_data <= ascii_tens; wr_en <= 1;
                        state <= UPDATE_V_2;
                    end
                    UPDATE_V_2: begin
                        wr_addr <= V_POS + 2; wr_data <= ascii_units; wr_en <= 1;
                        state <= IDLE;
                    end
                endcase

            //end
        end
    end

    logic [2:0] video_osd;
    logic [7:0] R_d1, R_d2, G_d1, G_d2, B_d1, B_d2;
    logic hsync_d1, hsync_d2, vsync_d1, vsync_d2;
    logic hblank_d1, hblank_d2, vblank_d1, vblank_d2;
    logic [9:0] x_d1, x_d2, y_d1, y_d2;
    logic osd_d1, osd_d2;
    logic osd_active_raw;
    logic disp_dbg;

    osd_timer #(.CLK_HZ(CLK_HZ), .DURATION_SEC(DURATION_SEC)) timer_inst (
        .clk(clk),
        .reset(reset),
        .enable(key_event),
        .active(osd_active_raw)
    );

    always_ff @(posedge clk) begin
            R_d1 <= R_in; R_d2 <= R_d1;
            G_d1 <= G_in; G_d2 <= G_d1;
            B_d1 <= B_in; B_d2 <= B_d1;
            hsync_d1 <= hsync_in; hsync_d2 <= hsync_d1;
            vsync_d1 <= vsync_in; vsync_d2 <= vsync_d1;
            hblank_d1 <= hblank; hblank_d2 <= hblank_d1;
            vblank_d1 <= vblank; vblank_d2 <= vblank_d1;
            x_d1 <= x_pix[9:0]; x_d2 <= x_d1;
            y_d1 <= y_pix[9:0]; y_d2 <= y_d1;
            osd_d1 <= osd_active_raw; osd_d2 <= osd_d1;
    end

    osd_overlay #(
        .CHAR_WIDTH(8), .CHAR_HEIGHT(8),
        .SCREEN_COLS(COLS), .SCREEN_ROWS(ROWS)
    ) osd_inst (
        .clk(clk),
        .reset(reset),
        .hblank(hblank_d2),
        .vblank(vblank_d2),
        .x(x_d2),
        .y(y_d2),
        .osd_active(osd_d2),
        .video_out(video_osd),
        .addr_b(char_rd_addr),
        .char_code(char_code),
        .disp_dbg(disp_dbg),
    );

    assign {R_out, G_out, B_out} = (video_osd == 3'b111) ? 24'hFF00FF : {R_d2, G_d2, B_d2};
    assign hsync_out = hsync_d2;
    assign vsync_out = vsync_d2;
    assign hblank_out = hblank_d2;
    assign vblank_out = vblank_d2;
    assign h_offset_out = h_offset;
    assign v_offset_out = v_offset;
endmodule
