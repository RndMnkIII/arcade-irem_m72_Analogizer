// Project: OSD Overlay
// File: bin_to_ascii_4digits.sv
// Description: Overlay module for displaying OSD (On-Screen Display) characters
//              on a VGA screen. It uses a character RAM and a font ROM to
//              generate the pixel data for the OSD characters.
// Author: @RndMnkIII
// Date: 2025-05-10
// License: MIT
//
`default_nettype none
module bin_to_ascii_4digits (
    input  logic        clk,
    input  logic        start,
    input  logic [13:0] bin_in,
    output logic [7:0]  ascii_thousands,
    output logic [7:0]  ascii_hundreds,
    output logic [7:0]  ascii_tens,
    output logic [7:0]  ascii_units,
    output logic        done
);

    logic [13:0] shift_reg;
    logic [3:0]  bcd [3:0];
    logic [4:0]  i;
    logic        busy;

    typedef enum logic [1:0] {IDLE, SHIFT, DONE} state_t;
    state_t state;

    assign done = (state == DONE);

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                if (start) begin
                    shift_reg <= bin_in;
                    bcd[0] <= 0;
                    bcd[1] <= 0;
                    bcd[2] <= 0;
                    bcd[3] <= 0;
                    i <= 14;
                    state <= SHIFT;
                end
            end
            SHIFT: begin
                // add-3 step
                for (int j = 0; j < 4; j++) begin
                    if (bcd[j] >= 5)
                        bcd[j] <= bcd[j] + 3;
                end

                // shift left
                bcd[3] <= {bcd[3][2:0], bcd[2][3]};
                bcd[2] <= {bcd[2][2:0], bcd[1][3]};
                bcd[1] <= {bcd[1][2:0], bcd[0][3]};
                bcd[0] <= {bcd[0][2:0], shift_reg[13]};
                shift_reg <= shift_reg << 1;
                i <= i - 1;

                if (i == 0)
                    state <= DONE;
            end
            DONE: begin
                state <= IDLE;
            end
        endcase
    end

    assign ascii_thousands = 8'h30 + bcd[3];
    assign ascii_hundreds  = 8'h30 + bcd[2];
    assign ascii_tens      = 8'h30 + bcd[1];
    assign ascii_units     = 8'h30 + bcd[0];

endmodule
