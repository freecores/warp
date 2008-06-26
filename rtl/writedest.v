/*
 * Image warping and decay, write destination pixel
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

module writedest(
	input clk,
	input rst,

	/* Data */
	input [29:0] d_addr,
	input [23:0] d_data,
	input d_ready,
	output d_next,

	/* WISHBONE master, write-only */
	output reg [31:0] mwb_adr_o,
	output reg mwb_stb_o, /* implies WE signal */
	input mwb_ack_i,
	output reg [31:0] mwb_dat_o,
	output [3:0] mwb_sel_o
);

assign mwb_sel_o = 4'b0111;

assign d_next = ~mwb_stb_o | mwb_ack_i;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		mwb_adr_o <= 0;
		mwb_stb_o <= 0;
		mwb_dat_o <= 0;
	end else begin
		if(mwb_ack_i) begin
			if(d_ready) begin
				mwb_adr_o <= {d_addr, 2'b00};
				mwb_dat_o <= {8'h00, d_data};
				mwb_stb_o <= 1;
			end else
				mwb_stb_o <= 0;
		end else begin
			if(d_ready & ~mwb_stb_o) begin
				mwb_adr_o <= {d_addr, 2'b00};
				mwb_dat_o <= {8'h00, d_data};
				mwb_stb_o <= 1;
			end
		end
	end
end

endmodule
