/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 7-3-2019 */

module jtframe_mister #(parameter
    BUTTONS                 = 2,
    GAME_INPUTS_ACTIVE_LOW  =1'b1,
    COLORW                  = 4,
    VIDEO_WIDTH             = 384,
    VIDEO_HEIGHT            = 224,
    SDRAMW                  = 23
)(
    input           clk_sys,
    input           clk_rom,
    input           clk_pico,
    input           pll_locked,
    // interface with microcontroller
    output [63:0]   status,
    inout  [45:0]   HPS_BUS,
    output [ 1:0]   buttons,
    // LED
    input  [ 1:0]   game_led,
    // Extension port (fake USB3)
    input  [ 6:0]   USER_IN,
    output [ 6:0]   USER_OUT,
    output          db15_en,
    output          show_osd,
    // Base video
    input [COLORW-1:0] game_r,
    input [COLORW-1:0] game_g,
    input [COLORW-1:0] game_b,
    input           LHBL,
    input           LVBL,
    input           hs,
    input           vs,
    input           pxl_cen,
    input           pxl2_cen,
    // Shadowmask
    output  [2:0]   shadowmask,
    output          shadowmask_2x,
    output          shadowmask_rot,
    // SDRAM interface
    inout  [15:0]   SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output [12:0]   SDRAM_A,        // SDRAM Address bus 13 Bits
    output          SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output          SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output          SDRAM_nWE,      // SDRAM Write Enable
    output          SDRAM_nCAS,     // SDRAM Column Address Strobe
    output          SDRAM_nRAS,     // SDRAM Row Address Strobe
    output          SDRAM_nCS,      // SDRAM Chip Select
    output [ 1:0]   SDRAM_BA,       // SDRAM Bank Address
    input           SDRAM_CLK,      // SDRAM Clock
    output          SDRAM_CKE,      // SDRAM Clock Enable

    // Signals to rotate the screen
`ifdef JTFRAME_VERTICAL
    output          FB_EN,
    output  [4:0]   FB_FORMAT,
    output [11:0]   FB_WIDTH,
    output [11:0]   FB_HEIGHT,
    output [31:0]   FB_BASE,
    output [13:0]   FB_STRIDE,
    input           FB_VBL,
    input           FB_LL,
    output          FB_FORCE_BLANK,

    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output          FB_PAL_CLK,
    output  [7:0]   FB_PAL_ADDR,
    output [23:0]   FB_PAL_DOUT,
    input  [23:0]   FB_PAL_DIN,
    output          FB_PAL_WR,
 `endif

    // DDR3 RAM
(*keep*)    output          DDRAM_CLK,
(*keep*)    input           DDRAM_BUSY,
(*keep*)    output  [7:0]   DDRAM_BURSTCNT,
(*keep*)    output [28:0]   DDRAM_ADDR,
(*keep*)    input  [63:0]   DDRAM_DOUT,
(*keep*)    input           DDRAM_DOUT_READY,
(*keep*)    output          DDRAM_RD,
(*keep*)    output [63:0]   DDRAM_DIN,
(*keep*)    output  [7:0]   DDRAM_BE,
(*keep*)    output          DDRAM_WE,

    // ROM programming
    output       [26:0] ioctl_addr,
    output       [ 7:0] ioctl_dout,
    output              ioctl_rom_wr,
    // NVRAM
    input        [ 7:0] ioctl_din,
    output              ioctl_ram,

    input               dwnld_busy,
    output              downloading,

    input  [SDRAMW-1:0] prog_addr,
    input        [15:0] prog_data,
    input        [ 1:0] prog_mask,
    input        [ 1:0] prog_ba,
    input               prog_we,
    input               prog_rd,
    output              prog_dst,
    output              prog_dok,
    output              prog_rdy,
    output              prog_ack,
    // ROM access from game
    input  [SDRAMW-1:0] ba0_addr,
    input  [SDRAMW-1:0] ba1_addr,
    input  [SDRAMW-1:0] ba2_addr,
    input  [SDRAMW-1:0] ba3_addr,
    input         [3:0] ba_rd,
    input         [3:0] ba_wr,
    output        [3:0] ba_ack,
    output        [3:0] ba_rdy,
    output        [3:0] ba_dst,
    output        [3:0] ba_dok,
    input        [15:0] ba0_din,
    input        [ 1:0] ba0_din_m,  // write mask
    output       [15:0] sdram_dout,
//////////// board
    output          rst,      // synchronous reset
    output          rst_n,    // asynchronous reset
    output          game_rst,
    output          game_rst_n,
    // reset forcing signals:
    input           rst_req,
    // joystick
    output  [ 9:0]  game_joystick1,
    output  [ 9:0]  game_joystick2,
    output  [ 9:0]  game_joystick3,
    output  [ 9:0]  game_joystick4,
    // left analogue stick
    output  [15:0]  joyana_l1,
    output  [15:0]  joyana_l2,
    output  [15:0]  joyana_l3,
    output  [15:0]  joyana_l4,
    // right analogue stick
    output  [15:0]  joyana_r1,
    output  [15:0]  joyana_r2,
    output  [15:0]  joyana_r3,
    output  [15:0]  joyana_r4,
    output  [ 3:0]  game_coin,
    output  [ 3:0]  game_start,
    output          game_service,
    // DIP and OSD settings
    output  [11:0]  hdmi_arx,
    output  [11:0]  hdmi_ary,
    output  [ 1:0]  rotate,

    output          enable_fm,
    output          enable_psg,

    output          dip_test,
    // scan doubler
    output    [7:0] scan2x_r,
    output    [7:0] scan2x_g,
    output    [7:0] scan2x_b,
    output          scan2x_hs,
    output          scan2x_vs,
    output          scan2x_clk,
    output          scan2x_cen,
    output          scan2x_de,
    output    [1:0] scan2x_sl,
    // non standard:
    output            dip_pause,
    inout             dip_flip,
    output    [ 1:0]  dip_fxlevel,
    // Control words
    output    [31:0]  dipsw,
    // Debug
    output            LED,
    output    [ 3:0]  gfx_en,
    output    [ 7:0]  debug_bus,
    output    [ 7:0]  st_addr,
    input     [ 7:0]  st_dout
);

`ifndef JTFRAME_MR_FASTIO
    `ifdef JTFRAME_CLK96
        `define JTFRAME_MR_FASTIO 1
    `else
      `define JTFRAME_MR_FASTIO 0
    `endif
`endif

localparam JTFRAME_MR_FASTIO=`JTFRAME_MR_FASTIO;

wire [21:0] gamma_bus;
wire [31:0] timestamp;
wire [ 7:0] ioctl_index;

wire [ 3:0] hoffset, voffset;
wire [31:0] cheat;
wire        ioctl_cheat, ioctl_lock;

wire [15:0] joystick1, joystick2, joystick3, joystick4;
wire        ps2_kbd_clk, ps2_kbd_data;
wire        force_scan2x, direct_video;

wire [ 6:0] core_mod;

wire        hs_resync, vs_resync;

// Horizontal scaling for CRT
wire        hsize_enable;
wire [3:0]  hsize_scale;
wire        hsize_hs, hsize_vs, hsize_hb, hsize_vb;
wire [COLORW-1:0] hsize_r, hsize_g, hsize_b;

wire        hps_download, hps_wr, hps_wait;
wire [15:0] hps_index;
wire [26:0] hps_addr;
wire [ 7:0] hps_dout;

// Screen rotation
wire [ 7:0] rot_burstcnt;
wire [28:0] rot_addr;
wire [63:0] rot_dout;
wire        rot_we, rot_rd, rot_busy;
wire [ 7:0] rot_be;

// Fast DDR load
wire [ 7:0] ddrld_burstcnt;
wire [28:0] ddrld_addr;
wire        ddrld_rd, ddrld_busy;

// H-Pos & V-Pos for CRT
assign { voffset, hoffset } = status[31:24];

// Horizontal scaling for CRT
assign hsize_enable = status[19];
assign hsize_scale  = status[23:20];

`ifdef JTFRAME_VERTICAL
assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;
`endif

// HDMI Shadowmask Overlay
assign shadowmask     = status[34:32];
assign shadowmask_2x  = status[35];
assign shadowmask_rot = core_mod[0] & rotate[0];


// assign SHADOWMASK = status[35:33];
// assign MASK_ROTATE = status[32];
// assign MASK_2X = status[36];

jtframe_resync u_resync(
    .clk        ( clk_sys       ),
    .pxl_cen    ( pxl_cen       ),
    .hs_in      ( hs            ),
    .vs_in      ( vs            ),
    .LVBL       ( LVBL          ),
    .LHBL       ( LHBL          ),
    .hoffset    ( hoffset       ),
    .voffset    ( voffset       ),
    .hs_out     ( hs_resync     ),
    .vs_out     ( vs_resync     )
);

wire [15:0] status_menumask; // a high value hides the menu item

assign status_menumask[15:4] = 0,
       status_menumask[3]    = shadowmask==0,    // shadow mask filter
       status_menumask[2]    = ~hsize_enable,    // horizontal scaling
       status_menumask[1]    = ~core_mod[0],     // vertical game
       status_menumask[0]    = direct_video;

jtframe_mister_dwnld u_dwnld(
    .rst            ( rst            ),
    .clk            ( clk_rom        ),

    .prog_we        ( prog_we        ),
    .prog_rdy       ( prog_rdy       ),
    .downloading    ( downloading    ),
    .dwnld_busy     ( dwnld_busy     ),

    .hps_download   ( hps_download   ),
    .hps_index      ( hps_index[7:0] ),
    .hps_wr         ( hps_wr         ),
    .hps_addr       ( hps_addr       ),
    .hps_dout       ( hps_dout       ),
    .hps_wait       ( hps_wait       ),

    .ioctl_rom_wr   ( ioctl_rom_wr   ),
    .ioctl_addr     ( ioctl_addr     ),
    .ioctl_dout     ( ioctl_dout     ),
    .ioctl_ram      ( ioctl_ram      ),
    .ioctl_cheat    ( ioctl_cheat    ),
    .ioctl_lock     ( ioctl_lock     ),

    // Configuration
    .core_mod       ( core_mod       ),
    .status         ( status         ),
    .dipsw          ( dipsw          ),
    .cheat          ( cheat          ),

    // DDR
    .ddram_busy     ( ddrld_busy       ),
    .ddram_burstcnt ( ddrld_burstcnt   ),
    .ddram_addr     ( ddrld_addr       ),
    .ddram_dout     ( DDRAM_DOUT       ),
    .ddram_dout_ready(DDRAM_DOUT_READY ),
    .ddram_rd       ( ddrld_rd         )
);

wire [7:0] hps_din;
wire [15:0] joyusb_1, joyusb_2;


`ifndef JTFRAME_NO_DB15
assign db15_en  = status[36];
jtframe_joymux #(.BUTTONS(BUTTONS)) u_joymux(
    .rst        ( rst       ),
    .clk        ( clk_sys   ),
    .show_osd   ( show_osd  ),

    // MiSTer pins
    .USER_IN    ( USER_IN   ),
    .USER_OUT   ( USER_OUT  ),

    // joystick mux
    .db15_en    ( db15_en   ),
    .joyusb_1   ( joyusb_1  ),
    .joyusb_2   ( joyusb_2  ),
    .joymux_1   ( joystick1 ),
    .joymux_2   ( joystick2 ),
);
`else
assign db15_en   = 0;
assign show_osd  = 0;
assign joystick1 = joyusb_1;
assign joystick2 = joyusb_2;
`endif

`ifdef JTFRAME_SHADOW
    jtframe_shadow #(
        .AW    ( SDRAMW              ),
        .START ( `JTFRAME_SHADOW     ),
        .LW    ( `JTFRAME_SHADOW_LEN )  // length of data to be dumped as a power of 2
    ) u_shadow (
        .clk_rom    ( clk_rom       ),

        // Capture SDRAM bank 0 inputs
        .ba0_addr   ( ba0_addr      ),
        .wr0        ( ba_wr[0]      ),
        .din        ( ba0_din       ),
        .din_m      ( ba0_din_m     ),  // write mask -active low

        // Let data be dumped via NVRAM interface
        .ioctl_addr ( ioctl_addr    ),
        .ioctl_din  ( hps_din       )
    );
`else
    assign hps_din = ioctl_din;
`endif

wire [9:0] cfg_addr;
wire [7:0] cfg_dout;

jtframe_ram #(.synfile("cfgstr.hex")) u_cfgstr(
    .clk    ( clk_rom   ),
    .cen    ( 1'b1      ),
    .data   (           ),
    .addr   ( cfg_addr  ),
    .we     ( 1'b0      ),
    .q      ( cfg_dout  )
);

hps_io #( .STRLEN(0), .PS2DIV(32), .WIDE(JTFRAME_MR_FASTIO) ) u_hps_io
(
    .clk_sys         ( clk_rom        ),
    .HPS_BUS         ( HPS_BUS        ),

    .conf_str        (                ),
    .cfg_addr        ( cfg_addr       ),
    .cfg_dout        ( cfg_dout       ),

    .buttons         ( buttons        ),
    .status          ( status         ),
    .status_menumask ( status_menumask),
    .gamma_bus       ( gamma_bus      ),
    .direct_video    ( direct_video   ),
    .forced_scandoubler(force_scan2x  ),

    .ioctl_download  ( hps_download   ),
    .ioctl_wr        ( hps_wr         ),
    .ioctl_addr      ( hps_addr       ),
    .ioctl_dout      ( hps_dout       ),
    .ioctl_din       ( hps_din        ),
    .ioctl_index     ( hps_index      ),
    .ioctl_wait      ( hps_wait       ),
    // NVRAM support
    .ioctl_upload    (                ), // no need
    .ioctl_rd        (                ), // no need

    .joy_raw         ( joystick1[5:0] | joystick2[5:0] ), // DB15 control
    .joystick_0      ( joyusb_1       ),
    .joystick_1      ( joyusb_2       ),
    .joystick_2      ( joystick3      ),
    .joystick_3      ( joystick4      ),
    .joystick_l_analog_0( joyana_l1   ),
    .joystick_l_analog_1( joyana_l2   ),
    .joystick_l_analog_2( joyana_l3   ),
    .joystick_l_analog_3( joyana_l4   ),
    .joystick_r_analog_0( joyana_r1   ),
    .joystick_r_analog_1( joyana_r2   ),
    .joystick_r_analog_2( joyana_r3   ),
    .joystick_r_analog_3( joyana_r4   ),
    .ps2_kbd_clk_out ( ps2_kbd_clk    ),
    .ps2_kbd_data_out( ps2_kbd_data   ),
    // Unused:
    .ps2_key         (                ),
    .RTC             (                ),
    .TIMESTAMP       ( timestamp      ),
    .ps2_mouse       (                ),
    .ps2_mouse_ext   (                ),
    .ioctl_file_ext  (                )
);

`ifndef DEBUG_NOHDMI
    // scales base video horizontally
    jtframe_hsize #(.COLORW(COLORW)) u_hsize(
        .clk        ( clk_sys   ),
        .pxl_cen    ( pxl_cen   ),
        .pxl2_cen   ( pxl2_cen  ),

        .scale      ( hsize_scale  ),
        .offset     ( 5'd0         ),
        .enable     ( hsize_enable ),

        .r_in       ( game_r    ),
        .g_in       ( game_g    ),
        .b_in       ( game_b    ),
        .HS_in      ( hs_resync ),
        .VS_in      ( vs_resync ),
        .HB_in      ( ~LHBL     ),
        .VB_in      ( ~LVBL     ),
        // filtered video
        .HS_out     ( hsize_hs  ),
        .VS_out     ( hsize_vs  ),
        .HB_out     ( hsize_hb  ),
        .VB_out     ( hsize_vb  ),
        .r_out      ( hsize_r   ),
        .g_out      ( hsize_g   ),
        .b_out      ( hsize_b   )
    );
`else
    assign hsize_hs = hs_resync;
    assign hsize_vs = vs_resync;
    assign hsize_hb = ~LHBL;
    assign hsize_vb = ~LVBL;
    assign hsize_r  = game_r;
    assign hsize_g  = game_g;
    assign hsize_b  = game_b;
`endif

jtframe_board #(
    .BUTTONS               ( BUTTONS              ),
    .GAME_INPUTS_ACTIVE_LOW(GAME_INPUTS_ACTIVE_LOW),
    .COLORW                ( COLORW               ),
    .VIDEO_WIDTH           ( VIDEO_WIDTH          ),
    .VIDEO_HEIGHT          ( VIDEO_HEIGHT         ),
    .SDRAMW                ( SDRAMW               ),
    .MISTER                ( 1                    )
) u_board(
    .rst            ( rst             ),
    .rst_n          ( rst_n           ),
    .game_rst       ( game_rst        ),
    .game_rst_n     ( game_rst_n      ),
    .rst_req        ( rst_req         ),
    .pll_locked     ( pll_locked      ),
    .downloading    ( dwnld_busy      ),

    .clk_sys        ( clk_sys         ),
    .clk_rom        ( clk_rom         ),
    .clk_pico       ( clk_pico        ),

    .core_mod       ( core_mod        ),
    // joystick
    .ps2_kbd_clk    ( ps2_kbd_clk     ),
    .ps2_kbd_data   ( ps2_kbd_data    ),
    .board_joystick1( joystick1       ),
    .board_joystick2( joystick2       ),
    .board_joystick3( joystick3       ),
    .board_joystick4( joystick4       ),
    .joyana_l1      ( joyana_l1       ),
    .joyana_r1      ( joyana_r1       ),
    .joyana_l2      ( joyana_l2       ),
    .joyana_r2      ( joyana_r2       ),
    .board_start    ( 4'd0            ),
    .board_coin     ( 4'd0            ),
    .game_joystick1 ( game_joystick1  ),
    .game_joystick2 ( game_joystick2  ),
    .game_joystick3 ( game_joystick3  ),
    .game_joystick4 ( game_joystick4  ),
    .game_coin      ( game_coin       ),
    .game_start     ( game_start      ),
    .game_service   ( game_service    ),
    // DIP and OSD settings
    .status         ( status          ),
    .enable_fm      ( enable_fm       ),
    .enable_psg     ( enable_psg      ),
    .dip_test       ( dip_test        ),
    .dip_pause      ( dip_pause       ),
    .dip_flip       ( dip_flip        ),
    .dip_fxlevel    ( dip_fxlevel     ),
    .timestamp      ( timestamp       ),
    // screen
    .gamma_bus      ( gamma_bus       ),
    .direct_video   ( direct_video    ),
    .hdmi_arx       ( hdmi_arx        ),
    .hdmi_ary       ( hdmi_ary        ),
    .rotate         ( rotate          ),
    // LED
    .osd_shown      ( 1'b0            ),
    .game_led       ( game_led        ),
    .led            ( LED             ),
    // Scan doubler output
    .scan2x_r       ( scan2x_r        ),
    .scan2x_g       ( scan2x_g        ),
    .scan2x_b       ( scan2x_b        ),
    .scan2x_hs      ( scan2x_hs       ),
    .scan2x_vs      ( scan2x_vs       ),
    .scan2x_clk     ( scan2x_clk      ),
    .scan2x_cen     ( scan2x_cen      ),
    .scan2x_de      ( scan2x_de       ),
    .scan2x_enb     ( ~force_scan2x   ),
    .scan2x_sl      ( scan2x_sl       ),

    // SDRAM interface
    // Bank 0: allows R/W
    .ba0_addr   ( ba0_addr      ),
    .ba1_addr   ( ba1_addr      ),
    .ba2_addr   ( ba2_addr      ),
    .ba3_addr   ( ba3_addr      ),
    .ba_rd      ( ba_rd         ),
    .ba_wr      ( ba_wr         ),
    .ba_dst     ( ba_dst        ),
    .ba_dok     ( ba_dok        ),
    .ba_rdy     ( ba_rdy        ),
    .ba_ack     ( ba_ack        ),
    .ba0_din    ( ba0_din       ),
    .ba0_din_m  ( ba0_din_m     ),  // write mask

    // ROM-load interface
    .prog_addr  ( prog_addr     ),
    .prog_ba    ( prog_ba       ),
    .prog_rd    ( prog_rd       ),
    .prog_we    ( prog_we       ),
    .prog_data  ( prog_data     ),
    .prog_mask  ( prog_mask     ),
    .prog_rdy   ( prog_rdy      ),
    .prog_dst   ( prog_dst      ),
    .prog_dok   ( prog_dok      ),
    .prog_ack   ( prog_ack      ),
    // SDRAM interface
    .SDRAM_DQ   ( SDRAM_DQ      ),
    .SDRAM_A    ( SDRAM_A       ),
    .SDRAM_DQML ( SDRAM_DQML    ),
    .SDRAM_DQMH ( SDRAM_DQMH    ),
    .SDRAM_nWE  ( SDRAM_nWE     ),
    .SDRAM_nCAS ( SDRAM_nCAS    ),
    .SDRAM_nRAS ( SDRAM_nRAS    ),
    .SDRAM_nCS  ( SDRAM_nCS     ),
    .SDRAM_BA   ( SDRAM_BA      ),
    .SDRAM_CKE  ( SDRAM_CKE     ),

    // Common signals
    .sdram_dout ( sdram_dout    ),

    // Cheat!
    .cheat          ( cheat           ),
    .prog_cheat     ( ioctl_cheat     ),
    .prog_lock      ( ioctl_lock      ),
    .ioctl_wr       ( hps_wr          ),
    .ioctl_dout     ( ioctl_dout      ),
    .ioctl_addr     ( ioctl_addr[7:0] ),
    .st_addr        ( st_addr         ),
    .st_dout        ( st_dout         ),
    // Base video
    .osd_rotate     ( rotate          ),
    .game_r         ( hsize_r         ),
    .game_g         ( hsize_g         ),
    .game_b         ( hsize_b         ),
    .LHBL           ( ~hsize_hb       ),
    .LVBL           ( ~hsize_vb       ),
    .hs             ( hsize_hs        ),
    .vs             ( hsize_vs        ),
    .pxl_cen        ( pxl_cen         ),
    .pxl2_cen       ( pxl2_cen        ),
    // Debug
    .gfx_en         ( gfx_en          ),
    .debug_bus      ( debug_bus       )
);

wire rot_clk;

`ifdef JTFRAME_VERTICAL
    `ifdef JTFRAME_MR_ROTCCW
    localparam ROTCCW=1;
    `else
    localparam ROTCCW=0;
    `endif
    screen_rotate u_rotate(
        .CLK_VIDEO      ( scan2x_clk     ),
        .CE_PIXEL       ( scan2x_cen     ),

        .VGA_R          ( scan2x_r       ),
        .VGA_G          ( scan2x_g       ),
        .VGA_B          ( scan2x_b       ),
        .VGA_HS         ( scan2x_hs      ),
        .VGA_VS         ( scan2x_vs      ),
        .VGA_DE         ( scan2x_de      ),

        .rotate_ccw     ( ROTCCW         ),
        .no_rotate      ( ~rotate[0]     ),

        .FB_EN          ( FB_EN          ),
        .FB_FORMAT      ( FB_FORMAT      ),
        .FB_WIDTH       ( FB_WIDTH       ),
        .FB_HEIGHT      ( FB_HEIGHT      ),
        .FB_BASE        ( FB_BASE        ),
        .FB_STRIDE      ( FB_STRIDE      ),
        .FB_VBL         ( FB_VBL         ),
        .FB_LL          ( FB_LL          ),

        //muxed
        .DDRAM_BUSY     ( rot_busy       ),
        .DDRAM_BURSTCNT ( rot_burstcnt   ),
        .DDRAM_ADDR     ( rot_addr       ),
        .DDRAM_BE       ( rot_be         ),
        .DDRAM_WE       ( rot_we         ),
        .DDRAM_RD       ( rot_rd         ),
        // umuxed
        .DDRAM_CLK      ( rot_clk        ), // same as clk_rom
        .DDRAM_DIN      ( DDRAM_DIN      )
    );
`else
    assign DDRAM_DIN=64'd0;
    assign rot_clk = clk_rom;
`endif

jtframe_mr_ddrmux u_ddrmux(
    .rst            ( rst             ),
    .clk            ( clk_rom         ),
    .downloading    ( downloading     ),
    // Fast DDR load
    .ddrld_burstcnt ( ddrld_burstcnt  ),
    .ddrld_addr     ( ddrld_addr      ),
    .ddrld_rd       ( ddrld_rd        ),
    .ddrld_busy     ( ddrld_busy      ),
    // Rotation signals
    .rot_clk        ( rot_clk         ),
    .rot_burstcnt   ( rot_burstcnt    ),
    .rot_addr       ( rot_addr        ),
    .rot_rd         ( rot_rd          ),
    .rot_we         ( rot_we          ),
    .rot_be         ( rot_be          ),
    .rot_busy       ( rot_busy        ),
    // DDR Signals
    .ddr_clk        ( DDRAM_CLK       ),
    .ddr_busy       ( DDRAM_BUSY      ),
    .ddr_burstcnt   ( DDRAM_BURSTCNT  ),
    .ddr_addr       ( DDRAM_ADDR      ),
    .ddr_rd         ( DDRAM_RD        ),
    .ddr_we         ( DDRAM_WE        ),
    .ddr_be         ( DDRAM_BE        )
);

endmodule
