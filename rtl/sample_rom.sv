//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, Martin Donlon
//------------------------------------------------------------------------------
//
// Irem M72 - Sample ROM
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

module sample_rom
    (
        input  wire       clk,
        input  wire       reset,

        input  wire  [7:0] sample_addr_in,
        input  wire  [1:0] sample_addr_wr,

        output reg   [7:0] sample_data,
        input              sample_inc,
        // ioctl
        output reg  [24:0] sample_rom_addr,
        input  wire [63:0] sample_rom_dout,
        output reg         sample_rom_req = 0,
        input  wire        sample_rom_ack
    );

    reg [17:0] sample_addr = 0;

    always_ff @(posedge clk) begin
        if (sample_inc) begin
            sample_addr     <= sample_addr + 18'd1;
            sample_rom_addr <= {REGION_SAMPLES.base_addr[24:18], sample_addr[17:0]};
            if(sample_addr[17:3] != sample_rom_addr[17:3]) begin
                sample_rom_req <= ~sample_rom_req;
            end
        end

        if (sample_addr_wr[0]) begin
            sample_addr[12:0] <= {sample_addr_in, 5'd0};
        end
        if (sample_addr_wr[1]) begin
            sample_addr[17:13] <= sample_addr_in[4:0];
            sample_rom_addr    <= {REGION_SAMPLES.base_addr[24:18], sample_addr_in[4:0], sample_addr[12:0]};
            sample_rom_req     <= ~sample_rom_req;
        end
    end

    always @(*) begin
        case(sample_rom_addr[2:0])
            3'd0:    sample_data = sample_rom_dout[ 7: 0];
            3'd1:    sample_data = sample_rom_dout[15: 8];
            3'd2:    sample_data = sample_rom_dout[23:16];
            3'd3:    sample_data = sample_rom_dout[31:24];
            3'd4:    sample_data = sample_rom_dout[39:32];
            3'd5:    sample_data = sample_rom_dout[47:40];
            3'd6:    sample_data = sample_rom_dout[55:48];
            default: sample_data = sample_rom_dout[63:56];
        endcase
        ;
    end

endmodule
