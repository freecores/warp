/*
 * Image warping and decay, WISHBONE control interface
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

module warpreg(
	input wb_clk_i,
	input wb_rst_i,
	
	/* WISHBONE interface */
	input [31:0] wb_adr_i,
	input wb_cyc_i,
	input wb_stb_i,
	input wb_we_i,
	output wb_ack_o,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	
	/* Control signals and registers */
	output enabled_write,		// 00 (0)
	input enabled_read,		// 00 (0)
	output reg [10:0] hres,		// 04 (1)
	output reg [10:0] vres,		// 08 (2)
	output reg [29:0] inaddr,	// 0C (3)
	output reg [29:0] outaddr,	// 10 (4)
	output reg [7:0] decay,		// 14 (5)
	output reg [6:0] meshcountx,	// 18 (6)
	output reg [10:0] meshsizex,	// 1C (7)
	output reg [6:0] meshcounty,	// 20 (8)
	output reg [10:0] meshsizey,	// 24 (9)
	output reg [29:0] meshaddr	// 28 (a)
);

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if(wb_rst_i) begin
		hres <= 640;
		vres <= 480;
		inaddr <= 0;
		outaddr <= 0;
		decay <= 8'h80;
		meshcountx <= 22;
		meshsizex <= 26;
		meshcounty <= 16;
		meshsizey <= 26;
		meshaddr <= 0;
	end else begin
		if(wb_cyc_i & wb_stb_i & wb_we_i) begin
			case(wb_adr_i[5:2])
				4'h1: hres <= wb_dat_i[10:0];
				4'h2: vres <= wb_dat_i[10:0];
				4'h3: inaddr <= wb_dat_i[31:2];
				4'h4: outaddr <= wb_dat_i[31:2];
				4'h5: decay <= wb_dat_i[7:0];
				4'h6: meshcountx <= wb_dat_i[6:0];
				4'h7: meshsizex <= wb_dat_i[10:0];
				4'h8: meshcounty <= wb_dat_i[6:0];
				4'h9: meshsizey <= wb_dat_i[10:0];
				4'ha: meshaddr <= wb_dat_i[31:2];
			endcase
		end
	end
end
assign enabled_write = wb_cyc_i & wb_stb_i & wb_we_i & (wb_adr_i[5:2] == 4'h0) & wb_dat_i[0];

assign wb_ack_o = wb_cyc_i & wb_stb_i;

always @(wb_adr_i[5:2] or enabled_read or hres or vres or inaddr or outaddr or decay or meshcountx or meshsizex or meshcounty or meshsizey or meshaddr) begin
	case(wb_adr_i[5:2])
		4'h0: wb_dat_o <= enabled_read;
		4'h1: wb_dat_o <= hres;
		4'h2: wb_dat_o <= vres;
		4'h3: wb_dat_o <= {inaddr, 2'b00};
		4'h4: wb_dat_o <= {outaddr, 2'b00};
		4'h5: wb_dat_o <= decay;
		4'h6: wb_dat_o <= meshcountx;
		4'h7: wb_dat_o <= meshsizex;
		4'h8: wb_dat_o <= meshcounty;
		4'h9: wb_dat_o <= meshsizey;
		4'ha: wb_dat_o <= {meshaddr, 2'b00};
		default: wb_dat_o <= 32'hxxxxxxxx;
	endcase
end

endmodule
