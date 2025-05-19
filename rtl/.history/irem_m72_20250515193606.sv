//------------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2024, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Irem M72 Compatible Gateware IP Core
//
// Copyright (c) 2024, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2023, Martin Donlon
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

`default_nettype none
`timescale 1ns/1ps

import m72_pkg::*;

module irem_m72
    (
        input  wire        clk_sys,             //! System Clock (32 MHz)
        input  wire        clk_ram,             //! SDRAM  Clock (96 MHz)
        input  wire        pll_locked,          //! PLL Locked
        input  wire        reset,               //! Reset
        // Core Config
        input  wire        pause,               //! Pause CPU
        input  wire  [1:0] video_timing,         //! Video Mode
        input  wire  [7:0] mod_sw,              //! DIP Switch 1 (Default: 8'h00)
        input  wire  [7:0] dsw_1,               //! DIP Switch 1 (Default: 8'h00)
        input  wire  [7:0] dsw_2,               //! DIP Switch 2 (Default: 8'h00)
        input  wire  [7:0] dsw_3,               //! DIP Switch 3 (Default: 8'h00)
        // Input - Player 1
        input  wire        p1_coin,  p1_start,  //! Mode  / Start
        input  wire        p1_up,    p1_left,   //! Up    / Left
        input  wire        p1_down,  p1_right,  //! Down  / Right
        input  wire        p1_btn_y, p1_btn_x,  //! Btn Y / X
        input  wire        p1_btn_b, p1_btn_a,  //! Btn B / A
        input  wire        p1_btn_l, p1_btn_r,  //! Btn L / R
        // Input - Player 2
        input  wire        p2_coin,  p2_start,  //! Mode  / Start
        input  wire        p2_up,    p2_left,   //! Up    / Left
        input  wire        p2_down,  p2_right,  //! Down  / Right
        input  wire        p2_btn_y, p2_btn_x,  //! Btn Y / X
        input  wire        p2_btn_b, p2_btn_a,  //! Btn B / A
        input  wire        p2_btn_l, p2_btn_r,  //! Btn L / R
        // Audio
        output wire [15:0] audio_l,             //! Left Channel Output
        output wire [15:0] audio_r,             //! Right Channel Output
        // Video Signals
        output wire  [7:0] video_r,             //! Red
        output wire  [7:0] video_g,             //! Green
        output wire  [7:0] video_b,             //! Blue
        output wire        video_hs,            //! Horizontal Sync
        output wire        video_vs,            //! Vertical Sync
        output wire        video_hb,            //! Horizontal Blank
        output wire        video_vb,            //! Vertical Blank
        output wire        video_ce,            //! Pixel Clock Enable (8 MHz)
        output reg   [2:0] video_preset,        //! Video Preset [0] 384x256  | [1] 384x256 @ 270Deg
        // I/O Controller
        input  wire [16:0] ioctl_index,         //! Data Index
        input  wire        ioctl_download,      //! Download
        input  wire        ioctl_wr,            //! Write Enable
        input  wire [26:0] ioctl_addr,          //! Data Address
        input  wire [15:0] ioctl_data,          //! Data Input
        // SDRAM Interface
        output wire        sdram_clk,           //! Clock
        output wire        sdram_cke,           //! Clock Enable
        inout  wire [15:0] sdram_dq,            //! 16-bit Bidirectional Data Bus
        output wire [12:0] sdram_a,             //! 13-bit Multiplexed Address Bus
        output wire        sdram_dqml,          //! Two Byte Masks
        output wire        sdram_dqmh,          //! Two Byte Masks
        output wire  [1:0] sdram_ba,            //! Two Banks
        output wire        sdram_we_n,          //! Write Enable
        output wire        sdram_ras_n,         //! Row Address Select
        output wire        sdram_cas_n          //! Columns Address Select
    );

    //--------------------------------------------------------------------------
    // Settings
    //--------------------------------------------------------------------------
    parameter [15:0] ROM_IDX   = 16'd1,
                     HSDAT_IDX = 16'd2,
                     NVRAM_IDX = 16'd3;

    //wire  [1:0] vidmode    =  dsw_3[1:0];
    wire  [1:0] vidmode    = video_timing;
    wire        en_layer_a = ~dsw_3[2];
    wire        en_layer_b = ~dsw_3[3];
    wire        en_sprites = ~dsw_3[4];
    wire        filters    = ~dsw_3[5];
    wire        video_50hz = vidmode == 1;
    wire        video_57hz = vidmode == 2;
    wire        video_60hz = vidmode == 3;

    assign video_preset = { 2'b00, mod_sw[0] };

    //--------------------------------------------------------------------------
    // Inputs
    //--------------------------------------------------------------------------
    wire  [3:0] p1_input      = ~{ p1_up, p1_down, p1_left, p1_right };
    wire  [3:0] p2_input      = ~{ p2_up, p2_down, p2_left, p2_right };
    wire  [3:0] p1_buttons    = ~{ p1_btn_a, p1_btn_b, p1_btn_y, p1_btn_x };
    wire  [3:0] p2_buttons    = ~{ p2_btn_a, p2_btn_b, p2_btn_y, p2_btn_x };

    wire  [1:0] coin_buttons  = ~{ p2_coin,  p1_coin  };
    wire  [1:0] start_buttons = ~{ p2_start, p1_start };
    wire [16:0] dip_sw        = ~{ dsw_2, dsw_1 };

    //--------------------------------------------------------------------------
    // IP Core RTL
    //--------------------------------------------------------------------------
    m72 m72
    (
        .CLK_32M           ( clk_sys           ),
        .CLK_96M           ( clk_ram           ),
        .ce_pix            ( video_ce          ),
        .reset_n           ( ~reset            ),

        .R                 ( video_r           ),
        .G                 ( video_g           ),
        .B                 ( video_b           ),
        .HSync             ( video_hs          ),
        .VSync             ( video_vs          ),
        .HBlank            ( video_hb          ),
        .VBlank            ( video_vb          ),

        .AUDIO_L           ( audio_l           ),
        .AUDIO_R           ( audio_r           ),

        .board_cfg         ( board_cfg         ),

        .coin              ( coin_buttons      ),
        .start_buttons     ( start_buttons     ),

        .p1_joystick       ( p1_input          ),
        .p2_joystick       ( p2_input          ),
        .p1_buttons        ( p1_buttons        ),
        .p2_buttons        ( p2_buttons        ),

        .dip_sw            ( dip_sw            ),

        .sdr_sprite_addr   ( sdr_sprite_addr   ),
        .sdr_sprite_dout   ( sdr_sprite_dout   ),
        .sdr_sprite_req    ( sdr_sprite_req    ),
        .sdr_sprite_ack    ( sdr_sprite_ack    ),

        .sdr_bg_data_a     ( sdr_bg_data_a     ),
        .sdr_bg_addr_a     ( sdr_bg_addr_a     ),
        .sdr_bg_req_a      ( sdr_bg_req_a      ),
        .sdr_bg_ack_a      ( sdr_bg_ack_a      ),

        .sdr_bg_data_b     ( sdr_bg_data_b     ),
        .sdr_bg_addr_b     ( sdr_bg_addr_b     ),
        .sdr_bg_req_b      ( sdr_bg_req_b      ),
        .sdr_bg_ack_b      ( sdr_bg_ack_b      ),

        .sdr_cpu_dout      ( sdr_cpu_dout      ),
        .sdr_cpu_din       ( sdr_cpu_din       ),
        .sdr_cpu_addr      ( sdr_cpu_addr      ),
        .sdr_cpu_req       ( sdr_cpu_req       ),
        .sdr_cpu_ack       ( sdr_cpu_ack       ),
        .sdr_cpu_wr_sel    ( sdr_cpu_wr_sel    ),

        .sdr_z80_ram_addr  ( sdr_z80_ram_addr  ),
        .sdr_z80_ram_data  ( sdr_z80_ram_data  ),
        .sdr_z80_ram_dout  ( sdr_z80_ram_dout  ),
        .sdr_z80_ram_we    ( sdr_z80_ram_we    ),
        .sdr_z80_ram_cs    ( sdr_z80_ram_cs    ),
        .sdr_z80_ram_valid ( sdr_z80_ram_valid ),

        .sample_rom_addr   ( sample_rom_addr   ),
        .sample_rom_dout   ( sample_rom_dout   ),
        .sample_rom_req    ( sample_rom_req    ),
        .sample_rom_ack    ( sample_rom_ack    ),

        .clk_bram          ( clk_sys           ),
        .bram_addr         ( bram_addr         ),
        .bram_data         ( bram_data         ),
        .bram_cs           ( bram_cs           ),
        .bram_wr           ( bram_wr           ),

        .pause_rq          ( pause             ),

        .en_layer_a        ( en_layer_a        ),
        .en_layer_b        ( en_layer_b        ),
        .en_sprites        ( en_sprites        ),
        .en_layer_palette  ( 1'b1              ),
        .en_sprite_palette ( 1'b1              ),
        .en_audio_filters  ( filters           ),

        .sprite_freeze     ( 1'b0              ),

        .video_50hz        ( video_50hz        ),
        .video_57hz        ( video_57hz        ),
        .video_60hz        ( video_60hz        )
    );

    //--------------------------------------------------------------------------
    // ROM download controller
    //--------------------------------------------------------------------------
    board_cfg_t board_cfg;
    wire        rom_download = ioctl_download && (ioctl_index == ROM_IDX);

    rom_loader rom_loader
    (
        .sys_clk     ( clk_sys      ),

        .ioctl_downl ( rom_download ),
        .ioctl_wr    ( ioctl_wr     ),
        .ioctl_data  ( ioctl_data   ),

        .ioctl_wait  (              ),

        .sdr_addr    ( sdr_rom_addr ),
        .sdr_data    ( sdr_rom_data ),
        .sdr_be      ( sdr_rom_be   ),
        .sdr_req     ( sdr_rom_req  ),
        .sdr_ack     ( sdr_rom_ack  ),

        .bram_addr   ( bram_addr    ),
        .bram_data   ( bram_data    ),
        .bram_cs     ( bram_cs      ),
        .bram_wr     ( bram_wr      ),

        .board_cfg   ( board_cfg    )
    );

    //--------------------------------------------------------------------------
    // SDRAM
    //--------------------------------------------------------------------------
    wire [63:0] sdr_sprite_dout;
    wire [24:1] sdr_sprite_addr;
    wire        sdr_sprite_req, sdr_sprite_ack;
        
    wire [31:0] sdr_bg_data_a;
    wire [24:0] sdr_bg_addr_a;
    wire        sdr_bg_req_a, sdr_bg_ack_a;

    wire [31:0] sdr_bg_data_b;
    wire [24:0] sdr_bg_addr_b;
    wire        sdr_bg_req_b, sdr_bg_ack_b;

    wire [15:0] sdr_cpu_dout, sdr_cpu_din;
    wire [24:0] sdr_cpu_addr;
    wire        sdr_cpu_req, sdr_cpu_ack;
    wire  [1:0] sdr_cpu_wr_sel;
                
    wire [24:0] sdr_rom_addr;
    wire [15:0] sdr_rom_data;
    wire  [1:0] sdr_rom_be;
    wire        sdr_rom_req;
    wire        sdr_rom_ack;

    wire [15:0] cpu2_ram_q;
    wire [24:0] sdr_z80_ram_addr;
    wire  [7:0] sdr_z80_ram_data;
    wire  [7:0] sdr_z80_ram_dout = sdr_z80_ram_addr[0] ? cpu2_ram_q[15:8] : cpu2_ram_q[7:0];
    wire        sdr_z80_ram_we;
    wire        sdr_z80_ram_cs;
    wire        sdr_z80_ram_valid;

    wire [24:0] sample_rom_addr;
    wire [63:0] sample_rom_dout;
    wire        sample_rom_req;
    wire        sample_rom_ack;

    wire        sdr_rom_write = ioctl_download && (ioctl_index == ROM_IDX);

    wire [19:0] bram_addr;
    wire  [7:0] bram_data;
    wire  [3:0] bram_cs;
    wire        bram_wr;

    assign sdram_clk = clk_ram;
    assign sdram_cke = 1'b1;

    sdram_4w #(104) sdram
    (
        .SDRAM_DQ      ( sdram_dq                                    ),
        .SDRAM_A       ( sdram_a                                     ),
        .SDRAM_DQML    ( sdram_dqml                                  ),
        .SDRAM_DQMH    ( sdram_dqmh                                  ),
        .SDRAM_BA      ( sdram_ba                                    ),
        .SDRAM_nCS     (                                             ),
        .SDRAM_nWE     ( sdram_we_n                                  ),
        .SDRAM_nRAS    ( sdram_ras_n                                 ),
        .SDRAM_nCAS    ( sdram_cas_n                                 ),
        .init_n        ( pll_locked                                  ),
        .clk           ( clk_ram                                     ),

        // Bank 0-1 ops
        .port1_a       ( sdr_rom_addr[24:1]                          ),
        .port1_req     ( sdr_rom_req                                 ),
        .port1_ack     ( sdr_rom_ack                                 ),
        .port1_we      ( sdr_rom_write                               ),
        .port1_ds      ( sdr_rom_be                                  ),
        .port1_d       ( sdr_rom_data                                ),
        .port1_q       ( sdr_rom_ack                                 ),

        // Main CPU
        .cpu1_rom_addr (                                             ),
        .cpu1_rom_cs   (                                             ),
        .cpu1_rom_q    (                                             ),
        .cpu1_rom_valid(                                             ),

        .cpu1_ram_req  ( sdr_cpu_req                                 ),
        .cpu1_ram_ack  ( sdr_cpu_ack                                 ),
        .cpu1_ram_addr ( sdr_cpu_addr[24:1]                          ),
        .cpu1_ram_we   ( |sdr_cpu_wr_sel                             ),
        .cpu1_ram_d    ( sdr_cpu_din                                 ),
        .cpu1_ram_q    ( sdr_cpu_dout                                ),
        .cpu1_ram_ds   ( |sdr_cpu_wr_sel ? sdr_cpu_wr_sel : 2'b11    ),

        // Audio Z80
        .cpu2_addr     ( sdr_z80_ram_addr[24:1]                      ),
        .cpu2_cs       ( sdr_z80_ram_cs                              ),
        .cpu2_valid    ( sdr_z80_ram_valid                           ),
        .cpu2_d        ( {sdr_z80_ram_data, sdr_z80_ram_data}        ),
        .cpu2_we       ( sdr_z80_ram_we                              ),
        .cpu2_ds       ( {sdr_z80_ram_addr[0], ~sdr_z80_ram_addr[0]} ),
        .cpu2_q        ( cpu2_ram_q                                  ),

        //
        .cpu3_addr     (                                             ),
        .cpu3_req      (                                             ),
        .cpu3_q        (                                             ),
        .cpu3_ack      (                                             ),

        // Bank 2-3 ops
        .port2_a       ( sdr_rom_addr[24:1]                          ),
        .port2_req     ( sdr_rom_req                                 ),
        .port2_ack     ( sdr_rom_ack                                 ),
        .port2_we      ( sdr_rom_write                               ),
        .port2_ds      ( sdr_rom_be                                  ),
        .port2_d       ( sdr_rom_data                                ),
        .port2_q       ( sdr_rom_ack                                 ),

        .gfx1_req      ( sdr_bg_req_a                                ),
        .gfx1_ack      ( sdr_bg_ack_a                                ),
        .gfx1_addr     ( sdr_bg_addr_a[24:1]                         ),
        .gfx1_q        ( sdr_bg_data_a                               ),
        
        .gfx2_req      ( sdr_bg_req_b                                ),
        .gfx2_ack      ( sdr_bg_ack_b                                ),
        .gfx2_addr     ( sdr_bg_addr_b[24:1]                         ),
        .gfx2_q        ( sdr_bg_data_b                               ),

        .sample_addr   ( {sample_rom_addr[22:3], 2'b00}              ),
        .sample_q      ( sample_rom_dout                             ),
        .sample_req    ( sample_rom_req                              ),
        .sample_ack    ( sample_rom_ack                              ),

        .sp_addr       ( sdr_sprite_addr                             ),
        .sp_req        ( sdr_sprite_req                              ),
        .sp_ack        ( sdr_sprite_ack                              ),
        .sp_q          ( sdr_sprite_dout                             )
    );

endmodule
