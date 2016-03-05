`timescale 1ns / 1ps

// VGA top module

module vga (
    input CLK100MHZ,
    input RESET,
    input [7:0] DATA_IN,
    input WR_EN,
    input [5:0] DATA_ADDR,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
    );

    parameter h_sync  = 112;
    parameter h_back  = 248;
    parameter h_disp  = 1280;
    parameter h_front = 48;
    parameter v_sync  = 3;
    parameter v_back  = 38;
    parameter v_disp  = 1024;
    parameter v_front = 1;

    localparam addr_width = $clog2(h_disp * v_disp / (8 * 8));
    localparam x_width    = $clog2(h_disp);
    localparam y_width    = $clog2(v_disp);

    wire pixel_clk;

    pixel_clock_gen pixel_clock (
        .clk_in1  ( CLK100MHZ ),
        .clk_out1 ( pixel_clk )
    );

    wire [7:0] char_read;
    wire [addr_width - 1 : 0] addr_read;

    vga_model #(
        .h_disp(h_disp),
        .v_disp(v_disp)
    ) model (
        .clk          ( pixel_clk ),
        .addr_read    ( addr_read ),
        .char_read    ( char_read ),
        .addr_write   ( { {(addr_width - $size(DATA_ADDR)){1'b0}}, DATA_ADDR }),
        .char_write   ( DATA_IN   ),
        .write_enable ( WR_EN     )
    );

    wire disp;
    wire [x_width - 1 : 0] x_pos;
    wire [y_width - 1 : 0] y_pos;

    vga_view #(
        .h_sync(h_sync),
        .h_back(h_back),
        .h_disp(h_disp),
        .h_front(h_front),
        .v_sync(v_sync),
        .v_back(v_back),
        .v_disp(v_disp),
        .v_front(v_front)
    ) view (
        // Global input
        .clk    ( pixel_clk ),
        .reset  ( RESET     ),
        // Output to pins
        .vga_hs ( VGA_HS    ),
        .vga_vs ( VGA_VS    ),
        // Output to controller
        .disp   ( disp      ),
        .x_pos  ( x_pos     ),
        .y_pos  ( y_pos     )
    );

    vga_ctrl #(
        .h_disp(h_disp),
        .v_disp(v_disp)
    ) ctrl (
        // Global input
        .clk    ( pixel_clk    ),
        .reset  ( RESET        ),
        // Input from model
        .char_read ( char_read ),
        // Input from viewer
        .disp   ( disp         ),
        .x_pos  ( x_pos        ),
        .y_pos  ( y_pos        ),
        // Output to model
        .addr_read ( addr_read ),
        // Output to pins
        .vga_r  ( VGA_R        ),
        .vga_g  ( VGA_G        ),
        .vga_b  ( VGA_B        )
    );

endmodule
