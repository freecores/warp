/*
 * 10-bit, 10-cycle integer divider, non pipelined
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

module divider10(
	input clk,

	input start,
	input [9:0] dividend,
	input [9:0] divider,
	
	output ready,
	output [9:0] quotient,
	output [9:0] remainder
);

reg [19:0] qr;
reg [10:0] diff;

assign remainder = qr[19:10];
assign quotient = qr[9:0];

reg [3:0] counter;
assign ready = (counter == 0);

reg [9:0] divider_r;

always @(posedge clk) begin
		if(start) begin
			counter = 10;
			qr = {10'd0, dividend};
			divider_r = divider;
		end else begin
			if(~ready) begin
				diff = qr[19:9] - {1'b0, divider_r};
				
				if(diff[10])
					qr = {qr[18:0], 1'b0};
				else
					qr = {diff[9:0], qr[8:0], 1'b1};
				counter = counter - 1;
			end
		end
end

endmodule
