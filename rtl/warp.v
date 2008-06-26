/*
 * Image warping and decay, top-level
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

module warp(
	/* Clock and Reset signals are shared between the two buses */
	input wb_clk_i,
	input wb_rst_i,
	
	/* Wishbone master for accessing image and warp mesh data */
	output [31:0] mwb_adr_o,
	output mwb_stb_o,
	output mwb_we_o,
	input mwb_ack_i,
	output [31:0] mwb_dat_o,
	input [31:0] mwb_dat_i,
	output [3:0] mwb_sel_o,

	/* Wishbone slave for configuration registers */
	input [31:0] wb_adr_i,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output wb_ack_o,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i
);

/*** REGISTER BANK ***/

wire enabled_read;
wire enabled_write;
wire [10:0] hres;
wire [10:0] vres;
wire [29:0] inaddr;
wire [29:0] outaddr;
wire [7:0] decay;
wire [6:0] meshcountx;
wire [10:0] meshsizex;
wire [6:0] meshcounty;
wire [10:0] meshsizey;
wire [29:0] meshaddr;

warpreg warpreg(
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	
	/* WISHBONE interface */
	.wb_adr_i(wb_adr_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_ack_o(wb_ack_o),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	
	/* Control signals and registers */
	.enabled_write(enabled_write),
	.enabled_read(enabled_read),
	.hres(hres),
	.vres(vres),
	.inaddr(inaddr),
	.outaddr(outaddr),
	.decay(decay),
	.meshcountx(meshcountx),
	.meshsizex(meshsizex),
	.meshcounty(meshcounty),
	.meshsizey(meshsizey),
	.meshaddr(meshaddr)
);

/*** ARBITER ***/

wire [31:0] fm_mwb_adr_o;
wire fm_mwb_stb_o;
wire fm_mwb_ack_i;
wire [31:0] fm_mwb_dat_i;

wire [31:0] fs_mwb_adr_o;
wire fs_mwb_stb_o;
wire fs_mwb_ack_i;
wire [31:0] fs_mwb_dat_i;

wire [31:0] w_mwb_adr_o;
wire w_mwb_stb_o;
wire w_mwb_ack_i;
wire [31:0] w_mwb_dat_o;
wire [3:0] w_mwb_sel_o;

arbiter3 arbiter3(
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	
	/* WISHBONE master */
	.mwb_adr_o(mwb_adr_o),
	.mwb_stb_o(mwb_stb_o),
	.mwb_we_o(mwb_we_o),
	.mwb_ack_i(mwb_ack_i),
	.mwb_dat_o(mwb_dat_o),
	.mwb_dat_i(mwb_dat_i),
	.mwb_sel_o(mwb_sel_o),
	
	/* WISHBONE slave input 0: fetchmesh unit */
	.s0wb_adr_i(fm_mwb_adr_o),
	.s0wb_stb_i(fm_mwb_stb_o),
	.s0wb_we_i(0),
	.s0wb_ack_o(fm_mwb_ack_i),
	.s0wb_dat_i(32'hxxxxxxxx),
	.s0wb_dat_o(fm_mwb_dat_i),
	.s0wb_sel_i(4'b1111),
	
	/* WISHBONE slave input 1 : fetchsource unit */
	.s1wb_adr_i(fs_mwb_adr_o),
	.s1wb_stb_i(fs_mwb_stb_o),
	.s1wb_we_i(0),
	.s1wb_ack_o(fs_mwb_ack_i),
	.s1wb_dat_i(32'hxxxxxxxx),
	.s1wb_dat_o(fs_mwb_dat_i),
	.s1wb_sel_i(4'b1111),
	
	/* WISHBONE slave input 2 : writedest unit */
	.s2wb_adr_i(w_mwb_adr_o),
	.s2wb_stb_i(w_mwb_stb_o),
	.s2wb_we_i(w_mwb_stb_o),
	.s2wb_ack_o(w_mwb_ack_i),
	.s2wb_dat_i(w_mwb_dat_o),
	.s2wb_dat_o(),
	.s2wb_sel_i(w_mwb_sel_o)
);

/*** PIPELINE ***/

/* Stage 1: Mesh reading */

/* fetchmesh wires */

wire fm_finished;

/* triangleamy wires */
wire [10:0] td_xa;
wire [10:0] td_ya;
wire [10:0] ts_xa;
wire [10:0] ts_ya;

wire [10:0] td_xb;
wire [10:0] td_yb;
wire [10:0] ts_xb;
wire [10:0] ts_yb;

wire [10:0] td_xc;
wire [10:0] td_yc;
wire [10:0] ts_xc;
wire [10:0] ts_yc;

wire t_load;
wire t_finished;

fetchmesh fetchmesh(
	.clk(wb_clk_i),
	.rst(wb_rst_i),

	/* WISHBONE master, read-only */
	.mwb_adr_o(fm_mwb_adr_o),
	.mwb_stb_o(fm_mwb_stb_o),
	.mwb_ack_i(fm_mwb_ack_i),
	.mwb_dat_i(fm_mwb_dat_i),
	
	/* Parameters */
	.meshaddr(meshaddr),
	.mesh_count_x(meshcountx),
	.mesh_size_x(meshsizex),
	.mesh_count_y(meshcounty),
	.mesh_size_y(meshsizey),
	
	/* Control */
	.start(enabled_write),
	.finished(fm_finished),

	/* Interface to the triangle interpolator */
	.td_xa(td_xa),
	.td_ya(td_ya),
	.ts_xa(ts_xa),
	.ts_ya(ts_ya),
	
	.td_xb(td_xb),
	.td_yb(td_yb),
	.ts_xb(ts_xb),
	.ts_yb(ts_yb),
	
	.td_xc(td_xc),
	.td_yc(td_yc),
	.ts_xc(ts_xc),
	.ts_yc(ts_yc),
	
	.t_load(t_load),
	.t_finished(t_finished)
);

/* Stage 2: Triangular interpolation */

wire [10:0] td_x;
wire [10:0] td_y;
wire [10:0] ts_x;
wire [10:0] ts_y;

wire t_next;
wire t_ready;

triangleany triangleany(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	
	.xa(td_xa),
	.ya(td_ya),
	.ua(ts_xa),
	.va(ts_ya),
	
	.xb(td_xb),
	.yb(td_yb),
	.ub(ts_xb),
	.vb(ts_yb),
	
	.xc(td_xc),
	.yc(td_yc),
	.uc(ts_xc),
	.vc(ts_yc),
	
	.load(t_load),
	
	.x(td_x),
	.y(td_y),
	.u(ts_x),
	.v(ts_y),
	.next(t_next),
	.ready(t_ready),
	.finished(t_finished)
);

/* Stage 3: Boundary check */

wire [10:0] td_x_checked;
wire [10:0] td_y_checked;
wire [10:0] ts_x_checked;
wire [10:0] ts_y_checked;

wire bc_ready;
wire bc_next;

boundarycheck boundarycheck(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	
	.hres(hres),
	.vres(vres),
	
	.td_x(td_x),
	.td_y(td_y),
	.ts_x(ts_x),
	.ts_y(ts_y),
	.t_ready(t_ready),
	.t_next(t_next),
	
	.td_x_checked(td_x_checked),
	.td_y_checked(td_y_checked),
	.ts_x_checked(ts_x_checked),
	.ts_y_checked(ts_y_checked),
	.bc_ready(bc_ready),
	.bc_next(bc_next)
);

//always @(bc_ready) $display("bc ready %b", bc_ready);

/* Stage 4: Compute pixel addresses */

wire [29:0] s_addr;
wire [29:0] d_addr;
wire pa_ready;
wire pa_next;

pixeladdresses pixeladdresses(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	
	.hres(hres),
	.inaddr(inaddr),
	.outaddr(outaddr),
	
	.td_x(td_x_checked),
	.td_y(td_y_checked),
	.ts_x(ts_x_checked),
	.ts_y(ts_y_checked),
	.t_ready(bc_ready),
	.t_next(bc_next),
	
	.s_addr(s_addr),
	.d_addr(d_addr),
	.pa_ready(pa_ready),
	.pa_next(pa_next)
);

//always @(pa_ready) $display("pa ready %b", pa_ready);

/* Stage 5: Fetch source pixel */

wire [23:0] s_data;
wire [29:0] d_addr2;
wire fs_ready;
wire fs_next;

fetchsource fetchsource(
	.clk(wb_clk_i),
	.rst(wb_rst_i),

	/* Source address, and fetched data */
	.s_addr(s_addr),
	.s_data(s_data),
	.pa_ready(pa_ready),
	.pa_next(pa_next),

	/* WISHBONE master, read-only */
	.mwb_adr_o(fs_mwb_adr_o),
	.mwb_stb_o(fs_mwb_stb_o),
	.mwb_ack_i(fs_mwb_ack_i),
	.mwb_dat_i(fs_mwb_dat_i),
	
	/* Register for the destination address */
	.d_addr(d_addr),
	.d_addr2(d_addr2),
	
	.fs_ready(fs_ready),
	.fs_next(fs_next)
);

//always @(fs_ready or fs_next) $display("fs_ready %b fs_next %b", fs_ready, fs_next);

/* Stage 6: Apply decay effect */

wire d_ready;
wire d_next;
wire [23:0] d_data;
wire [29:0] d_addr3;

decay decayunit(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	
	/* Parameters */
	.decay(decay),
	
	.fs_ready(fs_ready),
	.fs_next(fs_next),
	
	.s_data(s_data),
	.d_data(d_data),
	.d_ready(d_ready),
	.d_next(d_next),
	
	/* Register for the destination address */
	.d_addr(d_addr2),
	.d_addr2(d_addr3)
);

//always @(d_ready or d_next) $display("d_ready %b d_next %b", d_ready, d_next);

/* Stage 7: Write destination pixel */

writedest writedest(
	.clk(wb_clk_i),
	.rst(wb_rst_i),
	
	/* Data */
	.d_addr(d_addr3),
	.d_data(d_data),
	.d_ready(d_ready),
	.d_next(d_next),

	/* WISHBONE master, write-only */
	.mwb_adr_o(w_mwb_adr_o),
	.mwb_stb_o(w_mwb_stb_o),
	.mwb_ack_i(w_mwb_ack_i),
	.mwb_dat_o(w_mwb_dat_o),
	.mwb_sel_o(w_mwb_sel_o)
);

assign enabled_read = ~fm_finished;// | ~t_finished | bc_ready | pa_ready | fs_ready | d_ready | w_mwb_stb_o;

endmodule
