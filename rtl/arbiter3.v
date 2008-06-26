/*
 * Image warping and decay, bus arbiter
 * Copyright (C) 2008 Sebastien Bourdeauducq - http://lekernel.net
 * This file is part of Milkymist.
 *
 * Milkymist is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
 * USA.
 */

module arbiter3(
	/* Clock and Reset are shared on all busses */
	input wb_clk_i,
	input wb_rst_i,
	
	/* WISHBONE master */
	output [31:0] mwb_adr_o,
	output mwb_stb_o,
	output mwb_we_o,
	input mwb_ack_i,
	output [31:0] mwb_dat_o,
	input [31:0] mwb_dat_i,
	output [3:0] mwb_sel_o,
	
	/* WISHBONE slave input 0 */
	input [31:0] s0wb_adr_i,
	input s0wb_stb_i,
	input s0wb_we_i,
	output s0wb_ack_o,
	input [31:0] s0wb_dat_i,
	output [31:0] s0wb_dat_o,
	input [3:0] s0wb_sel_i,
	
	/* WISHBONE slave input 1 */
	input [31:0] s1wb_adr_i,
	input s1wb_stb_i,
	input s1wb_we_i,
	output s1wb_ack_o,
	input [31:0] s1wb_dat_i,
	output [31:0] s1wb_dat_o,
	input [3:0] s1wb_sel_i,
	
	/* WISHBONE slave input 2 */
	input [31:0] s2wb_adr_i,
	input s2wb_stb_i,
	input s2wb_we_i,
	output s2wb_ack_o,
	input [31:0] s2wb_dat_i,
	output [31:0] s2wb_dat_o,
	input [3:0] s2wb_sel_i
);

wire [2:0] gnt;

roundrobin3 roundrobin3(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	.req({s2wb_stb_i, s1wb_stb_i, s0wb_stb_i}),
	.gnt(gnt)
);

assign mwb_adr_o = ({32{gnt[2]}} & s2wb_adr_i)|({32{gnt[1]}} & s1wb_adr_i)|({32{gnt[0]}} & s0wb_adr_i);
assign mwb_stb_o = (gnt[2] & s2wb_stb_i)|(gnt[1] & s1wb_stb_i)|(gnt[0] & s0wb_stb_i);
assign mwb_we_o = (gnt[2] & s2wb_we_i)|(gnt[1] & s1wb_we_i)|(gnt[0] & s0wb_we_i);
assign mwb_dat_o = ({32{gnt[2]}} & s2wb_dat_i)|({32{gnt[1]}} & s1wb_dat_i)|({32{gnt[0]}} & s0wb_dat_i);
assign mwb_sel_o = ({4{gnt[2]}} & s2wb_sel_i)|({4{gnt[1]}} & s1wb_sel_i)|({4{gnt[0]}} & s0wb_sel_i);

assign s2wb_ack_o = gnt[2] & mwb_ack_i;
assign s2wb_dat_o = mwb_dat_i;
assign s1wb_ack_o = gnt[1] & mwb_ack_i;
assign s1wb_dat_o = mwb_dat_i;
assign s0wb_ack_o = gnt[0] & mwb_ack_i;
assign s0wb_dat_o = mwb_dat_i;

endmodule
