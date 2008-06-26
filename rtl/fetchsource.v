/*
 * Image warping and decay, source pixel fetching
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

module fetchsource(
	input clk,
	input rst,

	/* Source address, and fetched data */
	input [29:0] s_addr,
	output reg [23:0] s_data,
	input pa_ready,
	output pa_next,

	/* WISHBONE master, read-only */
	output [31:0] mwb_adr_o,
	output mwb_stb_o,
	input mwb_ack_i,
	input [31:0] mwb_dat_i,
	
	/* Register for the destination address */
	input [29:0] d_addr,
	output reg [29:0] d_addr2,
	
	output reg fs_ready,
	input fs_next
);

assign pa_next = fs_next & mwb_ack_i;

assign mwb_adr_o = {s_addr, 2'b00};
assign mwb_stb_o = pa_ready & ~fs_ready;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		s_data <= 0;
		fs_ready <= 0;
		d_addr2 <= 0;
	end else begin
		if(fs_next) begin
			if(pa_ready & mwb_ack_i) begin
				s_data <= mwb_dat_i[23:0];
				d_addr2 <= d_addr;
				fs_ready <= 1;
			end else
				fs_ready <= 0;
		end
	end
end

endmodule
