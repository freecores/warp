/*
 * Image warping and decay, boundary check
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

module boundarycheck(
	input clk,
	input rst,
	
	input [10:0] hres,
	input [10:0] vres,
	
	input [10:0] td_x,
	input [10:0] td_y,
	input [10:0] ts_x,
	input [10:0] ts_y,
	input t_ready,
	output t_next,
	
	output reg [10:0] td_x_checked,
	output reg [10:0] td_y_checked,
	output reg [10:0] ts_x_checked,
	output reg [10:0] ts_y_checked,
	output reg bc_ready,
	input bc_next
);

wire passed;
assign passed = (td_x < hres) & (td_y < vres) & (ts_x < hres) & (ts_y < vres);

assign t_next = ~passed | (~bc_ready | bc_next);

always @(posedge rst or posedge clk) begin
	if(rst) begin
		td_x_checked <= 0;
		td_y_checked <= 0;
		ts_x_checked <= 0;
		ts_y_checked <= 0;
		bc_ready <= 0;
	end else begin
		if(passed & t_ready & (~bc_ready | bc_next)) begin
			td_x_checked <= td_x;
			td_y_checked <= td_y;
			ts_x_checked <= ts_x;
			ts_y_checked <= ts_y;
			bc_ready <= 1;
		end else
			if(bc_next) bc_ready <= 0;
	end
end

endmodule
