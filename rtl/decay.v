/*
 * Image warping and decay, decay (fade-to-black) effect
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

module decay(
	input clk,
	input rst,
	
	/* Parameters */
	input [7:0] decay, // unregistered
	
	input fs_ready,
	output fs_next,
	
	input [23:0] s_data,
	output reg [23:0] d_data,
	output reg d_ready,
	input d_next,
	
	/* Register for the destination address */
	input [29:0] d_addr,
	output reg [29:0] d_addr2
);

assign fs_next = ~d_ready | d_next;

wire [15:0] decay1;
wire [15:0] decay2;
wire [15:0] decay3;
assign decay1 = s_data[23:16] * decay;
assign decay2 = s_data[15:8]  * decay;
assign decay3 = s_data[7:0]   * decay;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		d_data <= 0;
		d_ready <= 0;
		d_addr2 <= 0;
	end else begin
		if(fs_ready & (~d_ready | d_next)) begin
			d_data <= decay == 8'hff ? s_data : {decay1[15:8], decay2[15:8], decay3[15:8]};
			d_addr2 <= d_addr;
			d_ready <= 1;
		end else
			if(d_next) d_ready <= 0;
	end
end

endmodule
