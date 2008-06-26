/*
 * Image warping and decay, pixel addresses computation
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

module pixeladdresses(
	input clk,
	input rst,
	
	input [10:0] hres,
	input [29:0] inaddr,
	input [29:0] outaddr,
	
	input [10:0] td_x,
	input [10:0] td_y,
	input [10:0] ts_x,
	input [10:0] ts_y,
	input t_ready,
	output t_next,
	
	output reg [29:0] s_addr,
	output reg [29:0] d_addr,
	output reg pa_ready,
	input pa_next
);

assign t_next = ~pa_ready | pa_next;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		s_addr <= 0;
		d_addr <= 0;
		pa_ready <= 0;
	end else begin
		if(t_ready & (~pa_ready | pa_next)) begin
			s_addr <= inaddr + hres*ts_y + ts_x;
			d_addr <= outaddr + hres*td_y + td_x;
			pa_ready <= 1;
		end else if(pa_next)
			if(pa_next) pa_ready <= 0;
	end
end

endmodule
