//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2022, Martin Donlon
//------------------------------------------------------------------------------
//
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

`timescale 1ns / 1ps

module dpramv #(
    parameter width_a = 8,
    parameter widthad_a = 10,
    parameter init_file= "",
    parameter prefix= "",
    parameter p= ""
) (
    // Port A
    input   wire                clock_a,
    input   wire                wren_a,
    input   wire    [widthad_a-1:0]  address_a,
    input   wire    [width_a-1:0]  data_a,
    output  reg     [width_a-1:0]  q_a,

    // Port B
    input   wire                clock_b,
    input   wire                wren_b,
    input   wire    [widthad_a-1:0]  address_b,
    input   wire    [width_a-1:0]  data_b,
    output  reg     [width_a-1:0]  q_b
);

    initial begin
        if (init_file>0) begin
            $display("Loading rom.");
            $display(init_file);
            $readmemh(init_file, ram);
        end
    end


// Shared ramory
reg [width_a-1:0] ram[(2**widthad_a)-1:0];

// Port A
always @(posedge clock_a) begin
  if (wren_a) begin
      ram[address_a] <= data_a;
      q_a <= data_a;
  end else begin
      q_a <= ram[address_a];
  end
end

// Port B
always @(posedge clock_b) begin
    if(wren_b) begin
        q_b      <= data_b;
        ram[address_b] <= data_b;
    end else begin
        q_b <= ram[address_b];
    end
end

endmodule
