//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, Martin Donlon
//------------------------------------------------------------------------------
//
// Irem M72 - Palette chip
// Copyright (C) 2022 Martin Donlon
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//------------------------------------------------------------------------------

module kna91h014
    (
        input  wire        CLK_32M,
        input  wire        CE_PIX,

        input  wire  [7:0] CB,         // Pins 3-10.
        input  wire  [7:0] CA,         // Pins 11-18.

        input  wire        SELECT,     // Pin 50. "S"

        input  wire        E1_N,       // Pin 52.
        input  wire        E2_N,       // Pin 51. CBLK.

        input  wire        G,          // Pin 30. G_N.

        input  wire        MWR,        // Pin 29.
        input  wire        MRD,        // Pin 28.

        input  wire [15:0] DIN,        // Pins 25, 22-19 (split to input for Verilog).
        output reg  [15:0] DOUT,       // Pins 25, 22-19 (split to output for Verilog).
        output wire        DOUT_VALID,

        input  wire [19:0] A,          // Pins 53-60

        output reg   [4:0] RED,        // Pins 47-43.
        output reg   [4:0] GRN,        // Pins 42-40, 37-36.
        output reg   [4:0] BLU         // Pins 35-31.
    );

    wire [7:0] A_IN = A[8:1];
    wire [2:0] A_S  = { A[11], A[10], A[0] };

    wire [7:0] color_addr = SELECT ? CA : CB;

    // RAM Addr decoding...
    wire ram_a_cs = A_S==3'b000 | A_S==3'b110;
    wire ram_b_cs = A_S==3'b010;
    wire ram_c_cs = A_S==3'b100;

    // Write enable, and addr decoding for RAM writes.
    wire wr_ena = G & MWR;
    wire rd_ena = G & MRD;

    assign DOUT_VALID = rd_ena;

    // Palette RAM(s)
    reg [4:0] ram[1024];
    reg [1:0] cnt;
    reg [4:0] color_out;

    always @(negedge CLK_32M) begin
        cnt <= cnt + 1'd1;
        if (CE_PIX) begin
            cnt <= 0;
        end
        color_out <= ram[{cnt, color_addr}];
        case(cnt)
            2'b01: RED <= color_out;
            2'b10: GRN <= color_out;
            2'b11: BLU <= color_out;
            default:;
        endcase
    end

    wire [9:0] ram_a = {ram_a_cs ? 2'b00 : ram_b_cs ? 2'b01 : ram_c_cs ? 2'b10 : 2'b11, A_IN};

    always @(posedge CLK_32M) begin
        DOUT <= {11'd0, ram[ram_a]};
        if (wr_ena) begin
            ram[ram_a] <= DIN[4:0];
        end
    end

endmodule
