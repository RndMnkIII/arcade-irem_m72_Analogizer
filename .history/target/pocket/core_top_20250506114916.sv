//------------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// SPDX-FileType: SOURCE
// SPDX-FileCopyrightText: (c) 2023, OpenGateware authors and contributors
//------------------------------------------------------------------------------
//
// Copyright (c) 2023, Marcus Andrade <marcus@opengateware.org>
// Copyright (c) 2022, Analogue Enterprises Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//------------------------------------------------------------------------------
// Platform Specific top-level
// Instantiated by the real top-level: apf_top
//------------------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module core_top
    #(
         //!-------------------------------------------------------------------------
         //! System Configuration Parameters
         //!-------------------------------------------------------------------------
         // Memory
         parameter USE_SDRAM      = 1,     //! Enable SDRAM
         parameter USE_SRAM       = 0,     //! Enable SRAM
         parameter USE_CRAM0      = 0,     //! Enable Cellular RAM #1
         parameter USE_CRAM1      = 0,     //! Enable Cellular RAM #2
         // Video
         parameter BPP_R          = 8,     //! Bits Per Pixel Red
         parameter BPP_G          = 8,     //! Bits Per Pixel Green
         parameter BPP_B          = 8,     //! Bits Per Pixel Blue
         parameter USE_INTERLACED = 0,     //! Enable Interlaced Video Support
         parameter USE_VBL        = 0,     //! Capture and Use VBlank value at HSync
         parameter USE_ANALOGIZER = 1,     //! Enable Support for Analogizer
         // Audio
         parameter AUDIO_DW       = 16,    //! Audio Bits
         parameter AUDIO_S        = 1,     //! Signed Audio
         parameter STEREO         = 1,     //! Stereo Output
         parameter AUDIO_MIX      = 0,     //! [0] No Mix | [1] 25% | [2] 50% | [3] 100% (mono)
         parameter MUTE_PAUSE     = 1,     //! Mute Audio on Pause
         // Gamepad/Joystick
         parameter JOY_PADS       = 4,     //! Total Number of Gamepads
         parameter JOY_ALT        = 0,     //! 2 Players Alternate
         // Data I/O - [MPU -> FPGA]
         parameter DIO_MASK       = 4'h0,  //! Upper 4 bits of address
         parameter DIO_AW         = 27,    //! Address Width
         parameter DIO_DW         = 8,     //! Data Width (8 or 16 bits)
         parameter DIO_DELAY      = 7,     //! Number of clock cycles to delay each write output
         parameter DIO_HOLD       = 4,     //! Number of clock cycles to hold the ioctl_wr signal high
         // HiScore I/O - [MPU <-> FPGA]
         parameter HS_AW          = 16,    //! Max size of game RAM address for highscores
         parameter HS_SW          = 8,     //! Max size of capture RAM For highscore data (default 8 = 256 bytes max)
         parameter HS_CFG_AW      = 2,     //! Max size of RAM address for highscore.dat entries (default 4 = 16 entries max)
         parameter HS_CFG_LW      = 2,     //! Max size of length for each highscore.dat entries (default 1 = 256 bytes max)
         parameter HS_CONFIG      = 2,     //! Dataslot index for config transfer
         parameter HS_DATA        = 3,     //! Dataslot index for save data transfer
         parameter HS_MASK        = 4'h1,  //! Upper 4 bits of address
         parameter HS_WR_DELAY    = 4,     //! Number of clock cycles to delay each write output
         parameter HS_WR_HOLD     = 1,     //! Number of clock cycles to hold the nvram_wr signal high
         parameter HS_RD_DELAY    = 4,     //! Number of clock cycles it takes for a read to complete
         // Save I/O - [MPU <-> FPGA]
         parameter SIO_MASK       = 4'h1,  //! Upper 4 bits of address
         parameter SIO_AW         = 27,    //! Address Width
         parameter SIO_DW         = 8,     //! Data Width (8 or 16 bits)
         parameter SIO_WR_DELAY   = 4,     //! Number of clock cycles to delay each write output
         parameter SIO_WR_HOLD    = 1,     //! Number of clock cycles to hold the nvram_wr signal high
         parameter SIO_RD_DELAY   = 4,     //! Number of clock cycles it takes for a read to complete
         parameter SIO_SAVE_IDX   = 2      //! Dataslot index for save data transfer
     ) (
         //!---------------------------------------------------------------------
         //! Clock Inputs 74.25mhz.
         //! Not Phase Aligned, Treat These Domains as Asynchronous
         //!---------------------------------------------------------------------
         input wire          clk_74a, // mainclk1
         input wire          clk_74b, // mainclk1

         //!---------------------------------------------------------------------
         //! Cartridge Interface
         //!---------------------------------------------------------------------
         // switches between 3.3v and 5v mechanically
         // output enable for multibit translators controlled by pic32
         // GBA AD[15:8]
         inout  wire   [7:0] cart_tran_bank2,
         output wire         cart_tran_bank2_dir,
         // GBA AD[7:0]
         inout  wire   [7:0] cart_tran_bank3,
         output wire         cart_tran_bank3_dir,
         // GBA A[23:16]
         inout  wire   [7:0] cart_tran_bank1,
         output wire         cart_tran_bank1_dir,
         // GBA [7] PHI#
         // GBA [6] WR#
         // GBA [5] RD#
         // GBA [4] CS1#/CS#
         //     [3:0] unwired
         inout  wire   [7:4] cart_tran_bank0,
         output wire         cart_tran_bank0_dir,
         // GBA CS2#/RES#
         inout  wire         cart_tran_pin30,
         output wire         cart_tran_pin30_dir,
         // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
         // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
         // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
         // and general IO drive this pin.
         output wire         cart_pin30_pwroff_reset,
         // GBA IRQ/DRQ
         inout  wire         cart_tran_pin31,
         output wire         cart_tran_pin31_dir,

         //!---------------------------------------------------------------------
         //! Infrared
         //!---------------------------------------------------------------------
         input  wire         port_ir_rx,
         output wire         port_ir_tx,
         output wire         port_ir_rx_disable,

         //!---------------------------------------------------------------------
         //! GBA link port
         //!---------------------------------------------------------------------
         inout  wire         port_tran_si,
         output wire         port_tran_si_dir,
         inout  wire         port_tran_so,
         output wire         port_tran_so_dir,
         inout  wire         port_tran_sck,
         output wire         port_tran_sck_dir,
         inout  wire         port_tran_sd,
         output wire         port_tran_sd_dir,

         //!---------------------------------------------------------------------
         //! CellularRAM #0, 4Mx16 x2 [16 Mbyte] PSRAM (AS1C8M16PL-70BIN)
         //!---------------------------------------------------------------------
         output wire [21:16] cram0_a,       // Address bus
         inout  wire  [15:0] cram0_dq,      // Bidirectional data bus
         input  wire         cram0_wait,    // Wait
         output wire         cram0_clk,     // Clock
         output wire         cram0_adv_n,   // Address valid
         output wire         cram0_cre,     // Control register enable
         output wire         cram0_ce0_n,   // First Chip enable
         output wire         cram0_ce1_n,   // Second Chip enable
         output wire         cram0_oe_n,    // Output enable
         output wire         cram0_we_n,    // Write enable
         output wire         cram0_ub_n,    // Upper byte enable. DQ[15:8]
         output wire         cram0_lb_n,    // Lower byte enable. DQ[7:0]

         //!---------------------------------------------------------------------
         //! CellularRAM #1, 4Mx16 x2 [16 Mbyte] PSRAM (AS1C8M16PL-70BIN)
         //!---------------------------------------------------------------------
         output wire [21:16] cram1_a,       // Address bus
         inout  wire  [15:0] cram1_dq,      // Bidirectional data bus
         input  wire         cram1_wait,    // Wait
         output wire         cram1_clk,     // Clock
         output wire         cram1_adv_n,   // Address valid
         output wire         cram1_cre,     // Control register enable
         output wire         cram1_ce0_n,   // First Chip enable
         output wire         cram1_ce1_n,   // Second Chip enable
         output wire         cram1_oe_n,    // Output enable
         output wire         cram1_we_n,    // Write enable
         output wire         cram1_ub_n,    // Upper byte enable. DQ[15:8]
         output wire         cram1_lb_n,    // Lower byte enable. DQ[7:0]

         //!---------------------------------------------------------------------
         //! SDRAM, 32Mx16 [64 Mbyte] (AS4C32M16MSA-6BIN)
         //!---------------------------------------------------------------------
         output wire  [12:0] dram_a,        // Address bus
         output wire   [1:0] dram_ba,       // Bank select (single bits)
         inout  wire  [15:0] dram_dq,       // Bidirectional data bus
         output wire   [1:0] dram_dqm,      // High/low byte mask
         output wire         dram_clk,      // Clock
         output wire         dram_cke,      // Clock enable
         output wire         dram_ras_n,    // Select row address
         output wire         dram_cas_n,    // Select column address
         output wire         dram_we_n,     // Write enable

         //!---------------------------------------------------------------------
         //! SRAM, 128Kx16 [256 Kbyte] (AS6C2016-55BIN)
         //!---------------------------------------------------------------------
         output wire  [16:0] sram_a,        // Address bus
         inout  wire  [15:0] sram_dq,       // Bidirectional data bus
         output wire         sram_oe_n,     // Output enable
         output wire         sram_we_n,     // Write enable
         output wire         sram_ub_n,     // Upper Byte Mask
         output wire         sram_lb_n,     // Lower Byte Mask

         //!---------------------------------------------------------------------
         //! VBlank driven by dock for sync in a certain mode
         //!---------------------------------------------------------------------
         input  wire         vblank,

         //!---------------------------------------------------------------------
         //! I/O to 6515D breakout USB UART
         //!---------------------------------------------------------------------
         output wire         dbg_tx,
         input  wire         dbg_rx,

         //!---------------------------------------------------------------------
         //! I/O pads near jtag connector user can solder to
         //!---------------------------------------------------------------------
         output wire         user1,
         input  wire         user2,

         //!---------------------------------------------------------------------
         //! RFU internal i2c bus
         //!---------------------------------------------------------------------
         inout  wire         aux_sda,
         output wire         aux_scl,

         //!---------------------------------------------------------------------
         //! RFU, do not use !!!
         //!---------------------------------------------------------------------
         output wire         vpll_feed,

         //!---------------------------------------------------------------------
         //! Logical Connections ////////////////////////////////////////////////
         //!---------------------------------------------------------------------

         //!---------------------------------------------------------------------
         //! Video Output to Scaler
         //!---------------------------------------------------------------------
         output wire  [23:0] video_rgb,
         output wire         video_rgb_clock,
         output wire         video_rgb_clock_90,
         output wire         video_hs,
         output wire         video_vs,
         output wire         video_de,
         output wire         video_skip,

         //!---------------------------------------------------------------------
         //! Audio
         //!---------------------------------------------------------------------
         output wire         audio_mclk,
         output wire         audio_lrck,
         output wire         audio_dac,
         input  wire         audio_adc,

         //!---------------------------------------------------------------------
         //! Bridge Bus Connection (synchronous to clk_74a)
         //!---------------------------------------------------------------------
         output wire         bridge_endian_little,
         input  wire  [31:0] bridge_addr,
         input  wire         bridge_rd,
         output reg   [31:0] bridge_rd_data,
         input  wire         bridge_wr,
         input  wire  [31:0] bridge_wr_data,

         //!---------------------------------------------------------------------
         //! Controller Data
         //!---------------------------------------------------------------------
         input  wire  [31:0] cont1_key,
         input  wire  [31:0] cont2_key,
         input  wire  [31:0] cont3_key,
         input  wire  [31:0] cont4_key,
         input  wire  [31:0] cont1_joy,
         input  wire  [31:0] cont2_joy,
         input  wire  [31:0] cont3_joy,
         input  wire  [31:0] cont4_joy,
         input  wire  [15:0] cont1_trig,
         input  wire  [15:0] cont2_trig,
         input  wire  [15:0] cont3_trig,
         input  wire  [15:0] cont4_trig
     );

    localparam [7:0] ADDRESS_ANALOGIZER_CONFIG = 8'hF7;

    //!-------------------------------------------------------------------------
    //! Infrared
    //!-------------------------------------------------------------------------
    // not using the IR port, so turn off both the LED, and
    // disable the receive circuit to save power
    assign port_ir_tx         = 0;
    assign port_ir_rx_disable = 1;

    //!-------------------------------------------------------------------------
    //! Bridge endianness
    //!-------------------------------------------------------------------------
    assign bridge_endian_little = 0;

    //!-------------------------------------------------------------------------
    //! GB/GBA Link Port
    //!-------------------------------------------------------------------------
    // link port is input only
    assign port_tran_so      = 1'bZ;
    assign port_tran_so_dir  = 1'b0; // SO is output only
    assign port_tran_si      = 1'bZ;
    assign port_tran_si_dir  = 1'b0; // SI is input only
    assign port_tran_sck     = 1'bZ;
    assign port_tran_sck_dir = 1'b0; // clock direction can change
    assign port_tran_sd      = 1'bZ;
    assign port_tran_sd_dir  = 1'b0; // SD is input and not used

    //!-------------------------------------------------------------------------
    //! MISC
    //!-------------------------------------------------------------------------
    assign dbg_tx    = 1'bZ;
    assign user1     = 1'bZ;
    assign aux_scl   = 1'bZ;
    assign vpll_feed = 1'bZ;

    //! Tie off the memory the pins not being used /////////////////////////////
    generate
        //!---------------------------------------------------------------------
        //! Cartridge Slot
        //!---------------------------------------------------------------------
        // cart is unused, so set all level translators accordingly
        // directions are 0:IN, 1:OUT
        if(USE_ANALOGIZER == 0) begin
            assign cart_tran_bank3         = 8'hZZ;
            assign cart_tran_bank3_dir     = 1'b0;
            assign cart_tran_bank2         = 8'hZZ;
            assign cart_tran_bank2_dir     = 1'b0;
            assign cart_tran_bank1         = 8'hZZ;
            assign cart_tran_bank1_dir     = 1'b0;
            assign cart_tran_bank0         = 4'hF;
            assign cart_tran_bank0_dir     = 1'b1;
            assign cart_tran_pin30         = 1'b0;  // reset or cs2, we let the hw control it by itself
            assign cart_tran_pin30_dir     = 1'bZ;
            assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
            assign cart_tran_pin31         = 1'bZ;  // input
            assign cart_tran_pin31_dir     = 1'b0;  // input
        end
        //!---------------------------------------------------------------------
        //! Cellular RAM
        //!---------------------------------------------------------------------
        if(USE_CRAM0 == 0) begin
            assign cram0_a     = 'h0;
            assign cram0_dq    = {16{1'bZ}};
            assign cram0_clk   = 0;
            assign cram0_adv_n = 1;
            assign cram0_cre   = 0;
            assign cram0_ce0_n = 1;
            assign cram0_ce1_n = 1;
            assign cram0_oe_n  = 1;
            assign cram0_we_n  = 1;
            assign cram0_ub_n  = 1;
            assign cram0_lb_n  = 1;
        end
        if(USE_CRAM1 == 0) begin
            assign cram1_a     = 'h0;
            assign cram1_dq    = {16{1'bZ}};
            assign cram1_clk   = 0;
            assign cram1_adv_n = 1;
            assign cram1_cre   = 0;
            assign cram1_ce0_n = 1;
            assign cram1_ce1_n = 1;
            assign cram1_oe_n  = 1;
            assign cram1_we_n  = 1;
            assign cram1_ub_n  = 1;
            assign cram1_lb_n  = 1;
        end
        //!---------------------------------------------------------------------
        //! SDRAM
        //!---------------------------------------------------------------------
        if(USE_SDRAM == 0) begin
            assign dram_a     = 'h0;
            assign dram_ba    = 'h0;
            assign dram_dq    = {16{1'bZ}};
            assign dram_dqm   = 'h0;
            assign dram_clk   = 'h0;
            assign dram_cke   = 'h0;
            assign dram_ras_n = 'h1;
            assign dram_cas_n = 'h1;
            assign dram_we_n  = 'h1;
        end
        //!---------------------------------------------------------------------
        //! SRAM
        //!---------------------------------------------------------------------
        if(USE_SRAM == 0) begin
            assign sram_a    = 'h0;
            assign sram_dq   = {16{1'bZ}};
            assign sram_oe_n = 1;
            assign sram_we_n = 1;
            assign sram_ub_n = 1;
            assign sram_lb_n = 1;
        end
    endgenerate

    //!-------------------------------------------------------------------------
    //! Host/Target Command Handler
    //!-------------------------------------------------------------------------
    wire        reset_n;  // driven by host commands, can be used as core-wide reset
    wire [31:0] cmd_bridge_rd_data;

    // bridge host commands
    // synchronous to clk_74a
    wire        status_boot_done  = pll_core_locked_s;
    wire        status_setup_done = pll_core_locked_s; // rising edge triggers a target command
    wire        status_running    = reset_n;           // we are running as soon as reset_n goes high

    wire        dataslot_requestread;
    wire [15:0] dataslot_requestread_id;
    wire        dataslot_requestread_ack = 1;
    wire        dataslot_requestread_ok  = 1;

    wire        dataslot_requestwrite;
    wire [15:0] dataslot_requestwrite_id;
    wire [31:0] dataslot_requestwrite_size;
    wire        dataslot_requestwrite_ack = 1;
    wire        dataslot_requestwrite_ok  = 1;

    wire        dataslot_update;
    wire [15:0] dataslot_update_id;
    wire [31:0] dataslot_update_size;

    wire        dataslot_allcomplete;

    wire [31:0] rtc_epoch_seconds;
    wire [31:0] rtc_date_bcd;
    wire [31:0] rtc_time_bcd;
    wire        rtc_valid;

    wire        savestate_supported;
    wire [31:0] savestate_addr;
    wire [31:0] savestate_size;
    wire [31:0] savestate_maxloadsize;

    wire        savestate_start;
    wire        savestate_start_ack;
    wire        savestate_start_busy;
    wire        savestate_start_ok;
    wire        savestate_start_err;

    wire        savestate_load;
    wire        savestate_load_ack;
    wire        savestate_load_busy;
    wire        savestate_load_ok;
    wire        savestate_load_err;

    wire        osnotify_inmenu;
    wire        osnotify_docked;
    wire        osnotify_grayscale;

    // bridge target commands
    // synchronous to clk_74a
    reg         target_dataslot_read;
    reg         target_dataslot_write;
    reg         target_dataslot_getfile;    // require additional param/resp structs to be mapped
    reg         target_dataslot_openfile;   // require additional param/resp structs to be mapped

    wire        target_dataslot_ack;
    wire        target_dataslot_done;
    wire  [2:0] target_dataslot_err;

    reg  [15:0] target_dataslot_id;
    reg  [31:0] target_dataslot_slotoffset;
    reg  [31:0] target_dataslot_bridgeaddr;
    reg  [31:0] target_dataslot_length;

    wire [31:0] target_buffer_param_struct; // to be mapped/implemented when using some Target commands
    wire [31:0] target_buffer_resp_struct;  // to be mapped/implemented when using some Target commands

    // bridge data slot access
    // synchronous to clk_74a
    wire  [9:0] datatable_addr;
    wire        datatable_wren;
    wire [31:0] datatable_data;
    wire [31:0] datatable_q;

    core_bridge_cmd u_pocket_apf_bridge
    (
        .clk                        ( clk_74a                    ),
        .reset_n                    ( reset_n                    ),

        .bridge_endian_little       ( bridge_endian_little       ),
        .bridge_addr                ( bridge_addr                ),
        .bridge_rd                  ( bridge_rd                  ),
        .bridge_rd_data             ( cmd_bridge_rd_data         ),
        .bridge_wr                  ( bridge_wr                  ),
        .bridge_wr_data             ( bridge_wr_data             ),

        .status_boot_done           ( status_boot_done           ),
        .status_setup_done          ( status_setup_done          ),
        .status_running             ( status_running             ),

        .dataslot_requestread       ( dataslot_requestread       ),
        .dataslot_requestread_id    ( dataslot_requestread_id    ),
        .dataslot_requestread_ack   ( dataslot_requestread_ack   ),
        .dataslot_requestread_ok    ( dataslot_requestread_ok    ),

        .dataslot_requestwrite      ( dataslot_requestwrite      ),
        .dataslot_requestwrite_id   ( dataslot_requestwrite_id   ),
        .dataslot_requestwrite_size ( dataslot_requestwrite_size ),
        .dataslot_requestwrite_ack  ( dataslot_requestwrite_ack  ),
        .dataslot_requestwrite_ok   ( dataslot_requestwrite_ok   ),

        .dataslot_update            ( dataslot_update            ),
        .dataslot_update_id         ( dataslot_update_id         ),
        .dataslot_update_size       ( dataslot_update_size       ),

        .dataslot_allcomplete       ( dataslot_allcomplete       ),

        .rtc_epoch_seconds          ( rtc_epoch_seconds          ),
        .rtc_date_bcd               ( rtc_date_bcd               ),
        .rtc_time_bcd               ( rtc_time_bcd               ),
        .rtc_valid                  ( rtc_valid                  ),

        .savestate_supported        ( savestate_supported        ),
        .savestate_addr             ( savestate_addr             ),
        .savestate_size             ( savestate_size             ),
        .savestate_maxloadsize      ( savestate_maxloadsize      ),

        .savestate_start            ( savestate_start            ),
        .savestate_start_ack        ( savestate_start_ack        ),
        .savestate_start_busy       ( savestate_start_busy       ),
        .savestate_start_ok         ( savestate_start_ok         ),
        .savestate_start_err        ( savestate_start_err        ),

        .savestate_load             ( savestate_load             ),
        .savestate_load_ack         ( savestate_load_ack         ),
        .savestate_load_busy        ( savestate_load_busy        ),
        .savestate_load_ok          ( savestate_load_ok          ),
        .savestate_load_err         ( savestate_load_err         ),

        .osnotify_inmenu            ( osnotify_inmenu            ),
        .osnotify_docked            ( osnotify_docked            ),
        .osnotify_grayscale         ( osnotify_grayscale         ),

        .target_dataslot_read       ( target_dataslot_read       ),
        .target_dataslot_write      ( target_dataslot_write      ),
        .target_dataslot_getfile    ( target_dataslot_getfile    ),
        .target_dataslot_openfile   ( target_dataslot_openfile   ),

        .target_dataslot_ack        ( target_dataslot_ack        ),
        .target_dataslot_done       ( target_dataslot_done       ),
        .target_dataslot_err        ( target_dataslot_err        ),

        .target_dataslot_id         ( target_dataslot_id         ),
        .target_dataslot_slotoffset ( target_dataslot_slotoffset ),
        .target_dataslot_bridgeaddr ( target_dataslot_bridgeaddr ),
        .target_dataslot_length     ( target_dataslot_length     ),

        .target_buffer_param_struct ( target_buffer_param_struct ),
        .target_buffer_resp_struct  ( target_buffer_resp_struct  ),

        .datatable_addr             ( datatable_addr             ),
        .datatable_wren             ( datatable_wren             ),
        .datatable_data             ( datatable_data             ),
        .datatable_q                ( datatable_q                )
    );

    //! END OF APF /////////////////////////////////////////////////////////////

    //! ////////////////////////////////////////////////////////////////////////
    //! @ System Modules
    //! ////////////////////////////////////////////////////////////////////////

    //!-------------------------------------------------------------------------
    //! APF Bridge Read Data
    //!-------------------------------------------------------------------------
    wire [31:0] int_bridge_rd_data;
    wire [31:0] nvm_bridge_rd_data, nvm_bridge_rd_data_s;

    // Synchronize nvm_bridge_rd_data into clk_74a domain before usage
    synch_3 #(32) u_sync_nvm(nvm_bridge_rd_data, nvm_bridge_rd_data_s, clk_74a);

    always_comb begin
        casex(bridge_addr)
            32'hF8xxxxxx:                                begin bridge_rd_data <= cmd_bridge_rd_data;        end // APF Bridge (Reserved)
            32'h10000000:                                begin bridge_rd_data <= nvm_bridge_rd_data_s;      end // HiScore/NVRAM/SRAM Save
            32'hF0000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Reset
            32'hF0000010:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Service Mode Switch
            32'hF1000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // DIP Switches
            32'hF2000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Modifiers
            32'hF3000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // A/V Filters
            32'hF4000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Extra DIP Switches
            32'hF5000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // NVRAM Size
            {ADDRESS_ANALOGIZER_CONFIG,24'h0}:           begin bridge_rd_data <= analogizer_bridge_rd_data; end // Analogizer
            32'hFA000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Status Low  [31:0]
            32'hFB000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Status High [63:32]
            32'hFC000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Inputs
            32'hA0000000:                                begin bridge_rd_data <= int_bridge_rd_data;        end // Analogizer Settings
            default:                                     begin bridge_rd_data <= 32'h0;                     end
        endcase
    end

    //!-------------------------------------------------------------------------
    //! Pause Core (Analogue OS Menu/Module Request)
    //!-------------------------------------------------------------------------
    wire pause_core, pause_req;

    pause_crtl u_core_pause
    (
        .clk_sys    ( clk_sys         ),
        .os_inmenu  ( osnotify_inmenu ),
        .pause_req  ( pause_req       ),
        .pause_core ( pause_core      )
    );

    //!-------------------------------------------------------------------------
    //! Interact: Dip Switches, Modifiers, Filters and Reset
    //!-------------------------------------------------------------------------
    wire        reset_sw, svc_sw;
    wire  [7:0] dip_sw0, dip_sw1, dip_sw2, dip_sw3;
    wire  [7:0] ext_sw0, ext_sw1, ext_sw2, ext_sw3;
    wire  [7:0] mod_sw0, mod_sw1, mod_sw2, mod_sw3;
    wire  [7:0] inp_sw0, inp_sw1, inp_sw2, inp_sw3;
    wire  [3:0] scnl_sw, smask_sw, afilter_sw, vol_att;
    wire [63:0] status;
    wire [15:0] nvram_size;
    wire [31:0] analogizer_sw;

    interact u_pocket_interact
    (
        // Clocks and Reset
        .clk_74a        ( clk_74a            ), // [i]
        .clk_sync       ( clk_sys            ), // [i]
        .reset_n        ( reset_n            ), // [i]
        // Reset Switch
        .reset_sw       ( reset_sw           ), // [o]
        // Service Mode Switch
        .svc_sw         ( svc_sw             ), // [o]
        // DIP Switches
        .dip_sw0        ( dip_sw0            ), // [o]
        .dip_sw1        ( dip_sw1            ), // [o]
        .dip_sw2        ( dip_sw2            ), // [o]
        .dip_sw3        ( dip_sw3            ), // [o]
        // Extra DIP Switches
        .ext_sw0        ( ext_sw0            ), // [o]
        .ext_sw1        ( ext_sw1            ), // [o]
        .ext_sw2        ( ext_sw2            ), // [o]
        .ext_sw3        ( ext_sw3            ), // [o]
        // Modifiers
        .mod_sw0        ( mod_sw0            ), // [o]
        .mod_sw1        ( mod_sw1            ), // [o]
        .mod_sw2        ( mod_sw2            ), // [o]
        .mod_sw3        ( mod_sw3            ), // [o]
        // Inputs Switches
        .inp_sw0        ( inp_sw0            ), // [o]
        .inp_sw1        ( inp_sw1            ), // [o]
        .inp_sw2        ( inp_sw2            ), // [o]
        .inp_sw3        ( inp_sw3            ), // [o]
        // Status (Legacy Support)
        .status         ( status             ), // [o]
        // Filters Switches
        .scnl_sw        ( scnl_sw            ), // [o]
        .smask_sw       ( smask_sw           ), // [o]
        .afilter_sw     ( afilter_sw         ), // [o]
        .vol_att        ( vol_att            ), // [o]
        // NVRAM/High Score
        .nvram_size     ( nvram_size         ), // [o]
        // Analogizer
        .analogizer_sw  ( analogizer_sw      ), // [o]
        // Pocket Bridge
        .bridge_addr    ( bridge_addr        ), // [i]
        .bridge_wr      ( bridge_wr          ), // [i]
        .bridge_wr_data ( bridge_wr_data     ), // [i]
        .bridge_rd      ( bridge_rd          ), // [i]
        .bridge_rd_data ( int_bridge_rd_data )  // [o]
    );

    //!-------------------------------------------------------------------------
    //! Audio
    //!-------------------------------------------------------------------------
    wire [AUDIO_DW-1:0] core_snd_l, core_snd_r; // Audio Mono/Left/Right

    audio_mixer #(.DW(AUDIO_DW),.MUTE_PAUSE(MUTE_PAUSE),.STEREO(STEREO)) u_pocket_audio_mixer
    (
        // Clocks and Reset
        .clk_74b    ( clk_74b    ),
        .clk_sys    ( clk_sys    ),
        .reset      ( reset_sw   ),
        // Controls
        .afilter_sw ( afilter_sw ),
        .vol_att    ( vol_att    ),
        .mix        ( AUDIO_MIX  ),
        .pause_core ( pause_core ),
        // Audio From Core
        .is_signed  ( AUDIO_S    ),
        .core_l     ( core_snd_l ),
        .core_r     ( core_snd_r ),
        // I2S
        .audio_mclk ( audio_mclk ),
        .audio_lrck ( audio_lrck ),
        .audio_dac  ( audio_dac  )
    );

    //!-------------------------------------------------------------------------
    //! Video
    //!-------------------------------------------------------------------------
    wire             grayscale_en;           // Enable Grayscale Output
    wire       [2:0] video_preset;           // Video Preset Configuration
    wire [BPP_R-1:0] core_r;                 // Video Red
    wire [BPP_G-1:0] core_g;                 // Video Green
    wire [BPP_B-1:0] core_b;                 // Video Blue
    wire             core_hs, core_hb;       // Horizontal Sync/Blank
    wire             core_vs, core_vb;       // Vertical Sync/Blank
    wire             core_ce;                // Pixel Clock Enable (8 MHz)
    wire             interlaced, field;      // Interlaced Video | Even/Odd Field

    wire       [5:0] vga_r,  vga_g,  vga_b;  // VGA RGB
    wire             vga_vs, vga_hs, vga_de; // VGA H/V Sync and Display Enable (Blank_N)

    synch_3 sync_bwmode(osnotify_grayscale, grayscale_en, clk_vid);

    video_mixer #(
        .RW                       ( BPP_R                    ), // [p]
        .GW                       ( BPP_G                    ), // [p]
        .BW                       ( BPP_B                    )  // [p]
    ) u_pocket_video_mixer (
        // Clocks
        .clk_74a                  ( clk_74a                  ), // [i]
        .clk_sys                  ( clk_sys                  ), // [i]
        .clk_vid                  ( clk_vid                  ), // [i]
        .clk_vid_90deg            ( clk_vid_90deg            ), // [i]
        // Input Controls
        .grayscale_en             ( grayscale_en             ), // [i]
        .video_preset             ( video_preset             ), // [i]
        .scnl_sw                  ( scnl_sw                  ), // [i]
        .smask_sw                 ( smask_sw                 ), // [i]
         // Interlaced Video Controls
        .field                    ( field                    ), // [i]
        .interlaced               ( interlaced               ), // [i]
        // Input Video from Core
        .core_r                   ( video_rgb_irem72[23:16]  ), // [i]
        .core_g                   ( video_rgb_irem72[15:8]   ), // [i]
        .core_b                   ( video_rgb_irem72[7:0]    ), // [i]
        .core_hs                  ( core_hs                  ), // [i]
        .core_vs                  ( core_vs                  ), // [i]
        .core_hb                  ( core_hb                  ), // [i]
        .core_vb                  ( core_vb                  ), // [i]
        // Output to Display
        .video_rgb                ( video_rgb                ), // [o]
        .video_hs                 ( video_hs                 ), // [o]
        .video_vs                 ( video_vs                 ), // [o]
        .video_de                 ( video_de                 ), // [o]
        .video_skip               ( video_skip               ), // [o]
        .video_rgb_clock          ( video_rgb_clock          ), // [o]
        .video_rgb_clock_90       ( video_rgb_clock_90       ), // [o]
        // Input Video from Core
        .vga_r                    ( vga_r                    ), // [o]
        .vga_g                    ( vga_g                    ), // [o]
        .vga_b                    ( vga_b                    ), // [o]
        .vga_vs                   ( vga_vs                   ), // [o]
        .vga_hs                   ( vga_hs                   ), // [o]
        .vga_de                   ( vga_de                   )  // [o]
    );

    //!-------------------------------------------------------------------------
    //! Data I/O
    //!-------------------------------------------------------------------------
    wire              ioctl_download;
    wire       [15:0] ioctl_index;
    wire              ioctl_wr;
    wire [DIO_AW-1:0] ioctl_addr;
    wire [DIO_DW-1:0] ioctl_data;

    data_io #(.MASK(DIO_MASK),.AW(DIO_AW),.DW(DIO_DW),.DELAY(DIO_DELAY),.HOLD(DIO_HOLD)) u_pocket_data_io
    (
        // Clocks and Reset
        .clk_74a                  ( clk_74a                  ), // [i]
        .clk_memory               ( clk_sys                  ), // [i]
        // Pocket Bridge Slots
        .dataslot_requestwrite    ( dataslot_requestwrite    ), // [i]
        .dataslot_requestwrite_id ( dataslot_requestwrite_id ), // [i]
        .dataslot_allcomplete     ( dataslot_allcomplete     ), // [i]
        // MPU -> FPGA (MPU Write to FPGA)
        // Pocket Bridge
        .bridge_endian_little     ( bridge_endian_little     ), // [i]
        .bridge_addr              ( bridge_addr              ), // [i]
        .bridge_wr                ( bridge_wr                ), // [i]
        .bridge_wr_data           ( bridge_wr_data           ), // [i]
        // Controller Interface
        .ioctl_download           ( ioctl_download           ), // [o]
        .ioctl_index              ( ioctl_index              ), // [o]
        .ioctl_wr                 ( ioctl_wr                 ), // [o]
        .ioctl_addr               ( ioctl_addr               ), // [o]
        .ioctl_data               ( ioctl_data               )  // [o]
    );

    //! ------------------------------------------------------------------------
    //! Clocks
    //! ------------------------------------------------------------------------
    wire pll_core_locked, pll_core_locked_s;
    wire clk_sys;       //! Core :  32.000Mhz
    wire clk_vid;       //! Video:   8.000Mhz
    wire clk_vid_90deg; //! Video:   8.000Mhz @ 90deg Phase Shift
    wire clk_ram;       //! SDRAM: 96.000Mhz

    core_pll core_pll
    (
        .refclk   ( clk_74a         ),
        .rst      ( 0               ),

        .outclk_0 ( clk_ram         ),
        .outclk_1 ( clk_sys         ),
        .outclk_2 ( clk_vid         ),
        .outclk_3 ( clk_vid_90deg   ),

        .locked   ( pll_core_locked )
    );

    // Synchronize pll_core_locked into clk_74a domain before usage
    synch_3 sync_lck(pll_core_locked, pll_core_locked_s, clk_74a);

    //! ------------------------------------------------------------------------
    //! @ IP Core RTL
    //! ------------------------------------------------------------------------
    irem_m72 u_irem_m72_top
    (
        .clk_sys          ( clk_sys           ), // [i]
        .clk_ram          ( clk_ram           ), // [i]
        .pll_locked       ( pll_core_locked_s ), // [i]

        .reset            ( reset_sw          ), // [i]
        .pause            ( pause_core        ), // [i]

        .mod_sw           ( mod_sw0           ), // [i]
        .dsw_1            ( dip_sw0           ), // [i]
        .dsw_2            ( dip_sw1           ), // [i]
        .dsw_3            ( dip_sw2           ), // [i]

        .p1_coin          ( p1_controls[14]), // [i]
        .p1_start         ( p1_controls[15]), // [i]
        .p1_up            ( p1_controls[0]), // [i]
        .p1_left          ( p1_controls[2]), // [i]
        .p1_down          ( p1_controls[1]), // [i]
        .p1_right         ( p1_controls[3]), // [i]
        .p1_btn_y         ( p1_controls[7]), // [i]
        .p1_btn_x         ( p1_controls[6]), // [i]
        .p1_btn_b         ( p1_controls[5]), // [i]
        .p1_btn_a         ( p1_controls[4]), // [i]
        .p1_btn_l         ( p1_controls[8]), // [i]
        .p1_btn_r         ( p1_controls[9]), // [i]

        .p2_coin          ( p2_controls[14]), // [i]
        .p2_start         ( p2_controls[15]), // [i]
        .p2_up            ( p2_controls[0]), // [i]
        .p2_left          ( p2_controls[2]), // [i]
        .p2_down          ( p2_controls[1]), // [i]
        .p2_right         ( p2_controls[3]), // [i]
        .p2_btn_y         ( p2_controls[7]), // [i]
        .p2_btn_x         ( p2_controls[6]), // [i]
        .p2_btn_b         ( p2_controls[5]), // [i]
        .p2_btn_a         ( p2_controls[4]), // [i]
        .p2_btn_l         ( p2_controls[8]), // [i]
        .p2_btn_r         ( p2_controls[9]), // [i]

        .audio_l          ( core_snd_l        ), // [o]
        .audio_r          ( core_snd_r        ), // [o]

        .video_r          ( core_r            ), // [o]
        .video_g          ( core_g            ), // [o]
        .video_b          ( core_b            ), // [o]
        .video_hs         ( core_hs           ), // [o]
        .video_vs         ( core_vs           ), // [o]
        .video_hb         ( core_hb           ), // [o]
        .video_vb         ( core_vb           ), // [o]
        .video_ce         ( core_ce           ), // [o]

        .video_preset     ( video_preset      ), // [o]

        .ioctl_index      ( ioctl_index       ), // [i]
        .ioctl_download   ( ioctl_download    ), // [i]
        .ioctl_wr         ( ioctl_wr          ), // [i]
        .ioctl_addr       ( ioctl_addr        ), // [i]
        .ioctl_data       ( ioctl_data        ), // [i]

        .sdram_clk        ( dram_clk          ), // [o]
        .sdram_cke        ( dram_cke          ), // [o]
        .sdram_dq         ( dram_dq           ), // [b]
        .sdram_a          ( dram_a            ), // [o]
        .sdram_dqml       ( dram_dqm[0]       ), // [o]
        .sdram_dqmh       ( dram_dqm[1]       ), // [o]
        .sdram_ba         ( dram_ba           ), // [o]
        .sdram_we_n       ( dram_we_n         ), // [o]
        .sdram_ras_n      ( dram_ras_n        ), // [o]
        .sdram_cas_n      ( dram_cas_n        )  // [o]
    );

    /*[ANALOGIZER_HOOK_BEGIN]*/
    //reg analogizer_ena;
    wire [3:0] analogizer_video_type;
    wire [4:0] snac_game_cont_type;
    wire [3:0] snac_cont_assignment;
    wire       pocket_blank_screen;

    //create aditional switch to blank Pocket screen.
    wire [23:0] video_rgb_irem72;
    assign video_rgb_irem72 = (pocket_blank_screen) ? 24'h000000: {core_r,core_g,core_b};

    //switch between Analogizer SNAC and Pocket Controls for P1-P4 (P3,P4 when uses PCEngine Multitap)
    wire [15:0] p1_btn, p2_btn, p3_btn, p4_btn;
    wire [31:0] p1_joy, p2_joy;
    reg [31:0] p1_joystick, p2_joystick;
    reg  [15:0] p1_controls, p2_controls, p3_controls, p4_controls;

    wire snac_is_analog = (snac_game_cont_type == 5'h12) || (snac_game_cont_type == 5'h13);

    //! Player 1 ---------------------------------------------------------------------------
    reg p1_up, p1_down, p1_left, p1_right;
    wire p1_up_analog, p1_down_analog, p1_left_analog, p1_right_analog;
    //using left analog joypad
    assign p1_up_analog    = (p1_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign p1_down_analog  = (p1_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign p1_left_analog  = (p1_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign p1_right_analog = (p1_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        p1_up    <= (snac_is_analog) ? p1_up_analog    : p1_btn[0];
        p1_down  <= (snac_is_analog) ? p1_down_analog  : p1_btn[1];
        p1_left  <= (snac_is_analog) ? p1_left_analog  : p1_btn[2];
        p1_right <= (snac_is_analog) ? p1_right_analog : p1_btn[3];
    end
    //! Player 2 ---------------------------------------------------------------------------
    reg p2_up, p2_down, p2_left, p2_right;
    wire p2_up_analog, p2_down_analog, p2_left_analog, p2_right_analog;
    //using left analog joypad
    assign p2_up_analog    = (p2_joy[15:8] < 8'h40) ? 1'b1 : 1'b0; //analog range UP 0x00 Idle 0x7F DOWN 0xFF, DEADZONE +- 0x15
    assign p2_down_analog  = (p2_joy[15:8] > 8'hC0) ? 1'b1 : 1'b0; 
    assign p2_left_analog  = (p2_joy[7:0]  < 8'h40) ? 1'b1 : 1'b0; //analog range LEFT 0x00 Idle 0x7F RIGHT 0xFF, DEADZONE +- 0x15
    assign p2_right_analog = (p2_joy[7:0]  > 8'hC0) ? 1'b1 : 1'b0;

    always @(posedge clk_74a) begin
        p2_up    <= (snac_is_analog) ? p2_up_analog    : p2_btn[0];
        p2_down  <= (snac_is_analog) ? p2_down_analog  : p2_btn[1];
        p2_left  <= (snac_is_analog) ? p2_left_analog  : p2_btn[2];
        p2_right <= (snac_is_analog) ? p2_right_analog : p2_btn[3];
    end
    always @(posedge clk_74a) begin
        reg [31:0] p1_pocket_btn, p1_pocket_joy;
        reg [31:0] p2_pocket_btn, p2_pocket_joy;

        if(snac_game_cont_type == 5'h0) begin //SNAC is disabled
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
        end
        else begin
        case(snac_cont_assignment[1:0])
        2'h0:    begin  //SNAC P1 -> Pocket P1
            p1_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            p2_controls <= cont2_key;
            end
        2'h1: begin  //SNAC P1 -> Pocket P2
            p1_controls <= cont1_key;
            p2_controls <= p1_btn;
            end
        2'h2: begin //SNAC P1 -> Pocket P1, SNAC P2 -> Pocket P2
            p1_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            p2_controls <= {p2_btn[15:4],p2_right,p2_left,p2_down,p2_up};
            end
        2'h3: begin //SNAC P1 -> Pocket P2, SNAC P2 -> Pocket P1
            p1_controls <= {p2_btn[15:4],p2_right,p2_left,p2_down,p2_up};
            p2_controls <= {p1_btn[15:4],p1_right,p1_left,p1_down,p1_up};
            end
        default: begin 
            p1_controls <= cont1_key;
            p2_controls <= cont2_key;
            end
        endcase
        end
    end

    wire [15:0] p1_btn_CK, p2_btn_CK;
    wire [31:0] p1_joy_CK, p2_joy_CK;
    synch_3 #(
    .WIDTH(16)
    ) p1b_s (
        p1_btn_CK,
        p1_btn,
        clk_74a
    );

    synch_3 #(
        .WIDTH(16)
    ) p2b_s (
        p2_btn_CK,
        p2_btn,
        clk_74a
    );

    synch_3 #(
    .WIDTH(32)
    ) p3b_s (
        p1_joy_CK,
        p1_joy,
        clk_74a
    );
        
    synch_3 #(
        .WIDTH(32)
    ) p4b_s (
        p2_joy_CK,
        p2_joy,
        clk_74a
    );


    // Video Y/C Encoder settings
    // Follows the Mike Simone Y/C encoder settings:
    // https://github.com/MikeS11/MiSTerFPGA_YC_Encoder
    // SET PAL and NTSC TIMING and pass through status bits. ** YC must be enabled in the qsf file **
    wire [39:0] CHROMA_PHASE_INC;
    wire PALFLAG;

    parameter NTSC_REF = 3.579545;   
    parameter PAL_REF = 4.43361875;

    // Parameters to be modifed
    parameter CLK_VIDEO_NTSC = 32.0; // Must be filled E.g XX.X Hz - CLK_VIDEO
    parameter CLK_VIDEO_PAL  = 32.0; // Must be filled E.g XX.X Hz - CLK_VIDEO

    //PAL CLOCK FREQUENCY SHOULD BE 42.56274
    localparam [39:0] NTSC_PHASE_INC = 40'd122992229676; // ((NTSC_REF * 2^40) / CLK_VIDEO_NTSC)
    localparam [39:0] PAL_PHASE_INC  = 40'd152337980273; // ((PAL_REF * 2^40) / CLK_VIDEO_PAL)

    assign CHROMA_PHASE_INC = PALFLAG ? PAL_PHASE_INC : NTSC_PHASE_INC; 
    assign PALFLAG = (analogizer_video_type == 4'h4); 


    // H/V offset
    wire [3:0]	hoffset = 4'h8; //status[20:17];
    wire [3:0]	voffset = 4'h8; //status[24:21];
    wire HSync,VSync;
    jtframe_resync jtframe_resync
    (
        .clk(clk_sys),
        .pxl_cen(core_ce),
        .hs_in(core_hs),
        .vs_in(core_vs),
        .LVBL(~core_vb),
        .LHBL(~core_hb),
        .hoffset(hoffset),
        .voffset(voffset),
        .hs_out(HSync),
        .vs_out(VSync)
    );

    //32_000_000
    wire [31:0] analogizer_bridge_rd_data;
    openFPGA_Pocket_Analogizer #(.MASTER_CLK_FREQ(32_000_000), .LINE_LENGTH(512), .ADDRESS_ANALOGIZER_CONFIG(ADDRESS_ANALOGIZER_CONFIG)) analogizer (
        .clk_74a(clk_74a),
        .i_clk(clk_sys),
        .i_rst(reset_sw), //i_rst is active high
        .i_ena(1'b1),

        //Video interface
        .video_clk(clk_sys),
        .R(core_r),
        .G(core_g ),
        .B(core_b),
        .Hblank(core_hb),
        .Vblank(core_vb),
        .Hsync(HSync), //composite SYNC on HSync.
        .Vsync(VSync),

        //openFPGA Bridge interface
        .bridge_endian_little(bridge_endian_little),
        .bridge_addr(bridge_addr),
        .bridge_rd(bridge_rd),
        .analogizer_bridge_rd_data(analogizer_bridge_rd_data),
        .bridge_wr(bridge_wr),
        .bridge_wr_data(bridge_wr_data),

        //Analogizer settings
        .snac_game_cont_type_out(snac_game_cont_type),
        .snac_cont_assignment_out(snac_cont_assignment),
        .analogizer_video_type_out(analogizer_video_type),
        .SC_fx_out(),
        .pocket_blank_screen_out(pocket_blank_screen),
        .analogizer_osd_out(),

        //Video Y/C Encoder interface
        .CHROMA_PHASE_INC(CHROMA_PHASE_INC),
        .PALFLAG(PALFLAG),
        //Video SVGA Scandoubler interface
        .ce_pix(core_ce),
        .scandoubler(1'b1), //logic for disable/enable the scandoubler
        //SNAC interface
        .p1_btn_state(p1_btn_CK),
        .p1_joy_state(p1_joy_CK),
        .p2_btn_state(p2_btn_CK),  
        .p2_joy_state(p2_joy_CK),
        .p3_btn_state(),
        .p4_btn_state(),      
        //Pocket Analogizer IO interface to the Pocket cartridge port
        .cart_tran_bank2(cart_tran_bank2),
        .cart_tran_bank2_dir(cart_tran_bank2_dir),
        .cart_tran_bank3(cart_tran_bank3),
        .cart_tran_bank3_dir(cart_tran_bank3_dir),
        .cart_tran_bank1(cart_tran_bank1),
        .cart_tran_bank1_dir(cart_tran_bank1_dir),
        .cart_tran_bank0(cart_tran_bank0),
        .cart_tran_bank0_dir(cart_tran_bank0_dir),
        .cart_tran_pin30(cart_tran_pin30),
        .cart_tran_pin30_dir(cart_tran_pin30_dir),
        .cart_pin30_pwroff_reset(cart_pin30_pwroff_reset),
        .cart_tran_pin31(cart_tran_pin31),
        .cart_tran_pin31_dir(cart_tran_pin31_dir),
        //debug
        .o_stb()
    );
    /*[ANALOGIZER_HOOK_END]*/
endmodule
