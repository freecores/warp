/*
 * Image warping and decay, mesh data fetcher
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

module fetchmesh(
	input clk,
	input rst,

	/* WISHBONE master, read-only */
	output [31:0] mwb_adr_o,
	output reg mwb_stb_o,
	input mwb_ack_i,
	input [31:0] mwb_dat_i,
	
	/* Parameters */
	input [29:0] meshaddr,		// unregistered
	input [6:0] mesh_count_x,	// registered
	input [10:0] mesh_size_x,	// unregistered
	input [6:0] mesh_count_y,	// registered
	input [10:0] mesh_size_y,	// unregistered
	
	/* Control */
	input start,
	output reg finished,

	/* Interface to the triangle interpolator */
	output [10:0] td_xa,
	output [10:0] td_ya,
	output [10:0] ts_xa,
	output [10:0] ts_ya,
	
	output [10:0] td_xb,
	output [10:0] td_yb,
	output [10:0] ts_xb,
	output [10:0] ts_yb,
	
	output [10:0] td_xc,
	output [10:0] td_yc,
	output [10:0] ts_xc,
	output [10:0] ts_yc,
	
	output reg t_load,
	input t_finished
);

reg [29:0] adr_w;
assign mwb_adr_o = {adr_w, 2'b00};

reg [6:0] remain_meshx;
reg reset_remain_meshx;
reg dec_remain_meshx;
reg [6:0] remain_meshy;
reg reset_remain_meshy;
reg dec_remain_meshy;

reg reset_meshix;
reg inc_meshix;
reg dec_meshix;
reg reset_meshiy;
reg inc_meshiy;
reg dec_meshiy;

reg [10:0] dst_topleftx;
reg [10:0] dst_toplefty;
reg [10:0] dst_toprightx;
reg [10:0] dst_toprighty;
reg [10:0] dst_bottomleftx;
reg [10:0] dst_bottomlefty;
reg [10:0] dst_bottomrightx;
reg [10:0] dst_bottomrighty;

reg shiftright;
reg loaddst_topleft;
reg loaddst_topright;
reg loaddst_bottomleft;
reg loaddst_bottomright;

reg [10:0] src_topleftx;
reg [10:0] src_toplefty;
reg [10:0] src_toprightx;
reg [10:0] src_toprighty;
reg [10:0] src_bottomleftx;
reg [10:0] src_bottomlefty;
reg [10:0] src_bottomrightx;
reg [10:0] src_bottomrighty;

reg reset_srcx;
reg inc_srcx;
reg reset_srcy;
reg inc_srcy;

reg bottom_triangle;

reg [2:0] state;
reg [2:0] next_state;
parameter IDLE = 0, FETCH_TOPLEFT = 1, FETCH_BOTTOMLEFT = 2, FETCH_TOPRIGHT = 3, FETCH_BOTTOMRIGHT = 4,
	LOAD_TRIANGLE = 5, LOAD_TRIANGLE_BOTTOM = 6, NEXT_SQUARE = 7;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		state <= IDLE;
		
		remain_meshx <= 0;
		remain_meshy <= 0;
		
		adr_w <= 0;
		
		dst_topleftx <= 0;
		dst_toplefty <= 0;
		dst_toprightx <= 0;
		dst_toprighty <= 0;
		dst_bottomleftx <= 0;
		dst_bottomlefty <= 0;
		dst_bottomrightx <= 0;
		dst_bottomrighty <= 0;
		
		src_topleftx <= 0;
		src_toplefty <= 0;
		src_toprightx <= 0;
		src_toprighty <= 0;
		src_bottomleftx <= 0;
		src_bottomlefty <= 0;
		src_bottomrightx <= 0;
		src_bottomrighty <= 0;

	end else begin
		state <= next_state;
		//$display("state: %d -> %d", state, next_state);
		
		if(reset_remain_meshx)
			remain_meshx <= mesh_count_x;
		else if(dec_remain_meshx)
			remain_meshx <= remain_meshx - 1;
		if(reset_remain_meshy)
			remain_meshy <= mesh_count_y;
		else if(dec_remain_meshy)
			remain_meshy <= remain_meshy - 1;
		
		/*
		 * Mesh coordinates are 7-bit numbers that add to the base address (meshaddr input).
		 * We just store them in the word address register (adr_w).
		 * 29...7 Y
		 *  6...0 X
		 */
		
		if(reset_meshix)
			adr_w[6:0] <= meshaddr[6:0];
		else if(inc_meshix)
			adr_w[6:0] <= adr_w[6:0] + 1;
		else if(dec_meshix)
			adr_w[6:0] <= adr_w[6:0] - 1;
		if(reset_meshiy)
			adr_w[29:7] <= meshaddr[29:7];
		else if(inc_meshiy)
			adr_w[29:7] <= adr_w[29:7] + 1;
		else if(dec_meshiy)
			adr_w[29:7] <= adr_w[29:7] - 1;
		
		if(shiftright) begin
			dst_topleftx <= dst_toprightx;
			dst_toplefty <= dst_toprighty;
			dst_bottomleftx <= dst_bottomrightx;
			dst_bottomlefty <= dst_bottomrighty;
		end else begin
			if(loaddst_topleft) begin
				dst_topleftx <= mwb_dat_i[10:0];
				dst_toplefty <= mwb_dat_i[26:16];
			end
			if(loaddst_bottomleft) begin
				dst_bottomleftx <= mwb_dat_i[10:0];
				dst_bottomlefty <= mwb_dat_i[26:16];
			end
		end
		if(loaddst_topright) begin
			dst_toprightx <= mwb_dat_i[10:0];
			dst_toprighty <= mwb_dat_i[26:16];
		end
		if(loaddst_bottomright) begin
			dst_bottomrightx <= mwb_dat_i[10:0];
			dst_bottomrighty <= mwb_dat_i[26:16];
		end
		
		if(reset_srcx) begin
			src_topleftx <= 0;
			src_toprightx <= mesh_size_x;
			src_bottomleftx <= 0;
			src_bottomrightx <= mesh_size_x;
		end else if(inc_srcx) begin
			src_topleftx <= src_topleftx + mesh_size_x;
			src_toprightx <= src_toprightx + mesh_size_x;
			src_bottomleftx <= src_bottomleftx + mesh_size_x;
			src_bottomrightx <= src_bottomrightx + mesh_size_x;
		end
		
		if(reset_srcy) begin
			src_toplefty <= 0;
			src_toprighty <= 0;
			src_bottomlefty <= mesh_size_y;
			src_bottomrighty <= mesh_size_y;
		end else if(inc_srcy) begin
			src_toplefty <= src_toplefty + mesh_size_y;
			src_toprighty <= src_toprighty + mesh_size_y;
			src_bottomlefty <= src_bottomlefty + mesh_size_y;
			src_bottomrighty <= src_bottomrighty + mesh_size_y;
		end
	end
end

assign td_xa = bottom_triangle ? dst_bottomrightx : dst_topleftx;
assign td_ya = bottom_triangle ? dst_bottomrighty : dst_toplefty;
assign ts_xa = bottom_triangle ? src_bottomrightx : src_topleftx;
assign ts_ya = bottom_triangle ? src_bottomrighty : src_toplefty;

assign td_xb = dst_bottomleftx;
assign td_yb = dst_bottomlefty;
assign ts_xb = src_bottomleftx;
assign ts_yb = src_bottomlefty;

assign td_xc = dst_toprightx;
assign td_yc = dst_toprighty;
assign ts_xc = src_toprightx;
assign ts_yc = src_toprighty;

always @(state or start or mwb_ack_i or t_finished or bottom_triangle or remain_meshx or remain_meshy) begin
	/* XST does not generate a pure combinatorial function if next_state is
	 * not pre-affected, maybe because of the unused states.
	 */
	next_state = IDLE;

	finished = 0;
	
	reset_remain_meshx = 0;
	dec_remain_meshx = 0;
	reset_remain_meshy = 0;
	dec_remain_meshy = 0;
	
	reset_meshix = 0;
	inc_meshix = 0;
	dec_meshix = 0;
	reset_meshiy = 0;
	inc_meshiy = 0;
	dec_meshiy = 0;

	mwb_stb_o = 0;

	shiftright = 0;
	loaddst_topleft = 0;
	loaddst_topright = 0;
	loaddst_bottomleft = 0;
	loaddst_bottomright = 0;
	
	t_load = 0;
	
	reset_srcx = 0;
	inc_srcx = 0;
	reset_srcy = 0;
	inc_srcy = 0;
	
	bottom_triangle = 1'bx;

	case(state)
		IDLE: begin
			finished = 1;
		
			reset_meshix = 1;
			reset_remain_meshx = 1;
			reset_meshiy = 1;
			reset_remain_meshy = 1;
			reset_srcx = 1;
			reset_srcy = 1;
			if(start)
				next_state = FETCH_TOPLEFT;
			else
				next_state = IDLE;
		end
		
		FETCH_TOPLEFT: begin
			mwb_stb_o = 1;
			loaddst_topleft = 1;
			if(mwb_ack_i) begin
				inc_meshiy = 1;
				next_state = FETCH_BOTTOMLEFT;
			end else
				next_state = FETCH_TOPLEFT;
		end
		FETCH_BOTTOMLEFT: begin
			mwb_stb_o = 1;
			loaddst_bottomleft = 1;
			if(mwb_ack_i) begin
				inc_meshix = 1;
				dec_meshiy = 1;
				next_state = FETCH_TOPRIGHT;
			end else
				next_state = FETCH_BOTTOMLEFT;
		end
		FETCH_TOPRIGHT: begin
			mwb_stb_o = 1;
			loaddst_topright = 1;
			if(mwb_ack_i) begin
				inc_meshiy = 1;
				next_state = FETCH_BOTTOMRIGHT;
			end else
				next_state = FETCH_TOPRIGHT;
		end
		FETCH_BOTTOMRIGHT: begin
			mwb_stb_o = 1;
			loaddst_bottomright = 1;
			if(mwb_ack_i) begin
				dec_meshiy = 1;
				next_state = LOAD_TRIANGLE;
			end else
				next_state = FETCH_BOTTOMRIGHT;
		end
		
		LOAD_TRIANGLE: begin
			//$display("in square [T]: topleft (%d, %d) topright (%d, %d) bottomleft (%d, %d) bottomright (%d, %d) %b", dst_topleftx, dst_toplefty, dst_toprightx, dst_toprighty, dst_bottomleftx, dst_bottomlefty, dst_bottomrightx, dst_bottomrighty, t_finished);

			//$image_set(dst_topleftx, dst_toplefty, 32'h00ffffff);
			//$image_set(dst_toprightx, dst_toprighty, 32'h00ffffff);
			//$image_set(dst_bottomleftx, dst_bottomlefty, 32'h00ffffff);
			//$image_set(dst_bottomrightx, dst_bottomrighty, 32'h00ffffff);

			bottom_triangle = 0;
			if(t_finished) begin
				t_load = 1;
				next_state = LOAD_TRIANGLE_BOTTOM;
			end else
				next_state = LOAD_TRIANGLE;
		end
		
		LOAD_TRIANGLE_BOTTOM: begin
			//$display("in square [B]: topleft (%d, %d) topright (%d, %d) bottomleft (%d, %d) bottomright (%d, %d) %b", dst_topleftx, dst_toplefty, dst_toprightx, dst_toprighty, dst_bottomleftx, dst_bottomlefty, dst_bottomrightx, dst_bottomrighty, t_finished);

			bottom_triangle = 1;
			if(t_finished) begin
				t_load = 1;
				next_state = NEXT_SQUARE;
			end else
				next_state = LOAD_TRIANGLE_BOTTOM;
		end
		
		NEXT_SQUARE: begin
			if(remain_meshx == 0) begin
				reset_srcx = 1;
				inc_srcy = 1;
				dec_remain_meshy = 1;
				reset_meshix = 1;
				reset_remain_meshx = 1;
				inc_meshiy = 1;
				
				if(remain_meshy == 0)
					next_state = IDLE;
				else
					next_state = FETCH_TOPLEFT;
			end else begin
				shiftright = 1;
				inc_srcx = 1;
				inc_meshix = 1;
				dec_remain_meshx = 1;
				next_state = FETCH_TOPRIGHT;
			end
		end
	endcase
end

endmodule

