/*
 * Bresenham-like interpolator
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

/* This core computes the best integer linear interpolation
 * between the points (x1, y1) and (x2, y2) with incrementing x's.
 * Condition: x1 < x2.
 */

module bresenham(
	input clk,
	
	input [10:0] x1,
	input [10:0] y1,
	input [10:0] x2,
	input [10:0] y2,
	input load,
	output ready,
	
	output reg [10:0] x,
	output reg [10:0] y,
	input next,
	output finished
);

wire quadrant_c;
wire [9:0] eps_dx_c;
wire [9:0] dy_c;

assign eps_dx_c = x2 - x1;
assign quadrant_c = y2 > y1;
assign dy_c = quadrant_c ? y2 - y1 : y1 - y2;

wire d_ready;
wire [9:0] qy;
wire [9:0] ry; // add trailing zero

assign ready = d_ready;

divider10 divider(
	.clk(clk),
	
	.start(load),
	.dividend(dy_c),
	.divider(eps_dx_c),
	
	.ready(d_ready),
	.quotient(qy),
	.remainder(ry)
);

reg quadrant;
reg [9:0] dx; // add trailing zero
reg [10:0] eps;

assign finished = x == x2;

always @(posedge clk) begin
	if(load) begin
		//$display("interp %d -> %d", x1, x2);
		//$display("       %d -> %d", y1, y2);
		eps = eps_dx_c;
		dx = eps_dx_c;
		quadrant = quadrant_c;
		x = x1;
		y = y1;
	end else if(next & d_ready & ~finished) begin
		x = x + 1;
		if(quadrant)
			y = y + qy;
		else
			y = y - qy;
		if(eps <= {ry, 1'b0}) begin
			if(quadrant)
				y = y + 1;
			else
				y = y - 1;
			eps = eps + ({dx, 1'b0} - {ry, 1'b0});
		end else
			eps = eps - {ry, 1'b0};
	end
end

endmodule
