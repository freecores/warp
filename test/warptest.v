/*
 * Testbench for the image warping core
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

module warptest();

reg wb_clk_i;
reg wb_rst_i;

wire [31:0] mwb_adr_o;
wire mwb_stb_o;
wire mwb_we_o;
reg mwb_ack_i;
wire [31:0] mwb_dat_o;
reg [31:0] mwb_dat_i;
wire [3:0] mwb_sel_o;

reg [31:0] wb_adr_i;
wire wb_cyc_i;
reg wb_stb_i;
reg wb_we_i;
wire wb_ack_o;
wire [31:0] wb_dat_o;
reg [31:0] wb_dat_i;

warp dut(
	.wb_clk_i(wb_clk_i),
	.wb_rst_i(wb_rst_i),
	
	.mwb_adr_o(mwb_adr_o),
	.mwb_stb_o(mwb_stb_o),
	.mwb_we_o(mwb_we_o),
	.mwb_ack_i(mwb_ack_i),
	.mwb_dat_o(mwb_dat_o),
	.mwb_dat_i(mwb_dat_i),
	.mwb_sel_o(mwb_sel_o),

	.wb_adr_i(wb_adr_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_stb_i(wb_stb_i),
	.wb_we_i(wb_we_i),
	.wb_ack_o(wb_ack_o),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i)
);

parameter hres = 320;
parameter vres = 228;

initial mwb_ack_i = 0;

wire [6:0] meshx;
wire [6:0] meshy;

assign meshx = mwb_adr_o[8:2];
assign meshy = mwb_adr_o[15:9];

wire [27:0] px;
assign px = mwb_adr_o[29:2] % hres;
wire [27:0] py;
assign py = mwb_adr_o[29:2] / hres;

always @(posedge wb_clk_i) begin
	mwb_ack_i = mwb_ack_i ^ mwb_stb_o;
	if(mwb_stb_o) begin
		//$display("CYCLE we=%b adr=%x do=%x", mwb_we_o, mwb_adr_o, mwb_dat_o);
		if(mwb_adr_o[31]) begin
			mwb_dat_i[15:0]  = meshx*50+meshy*6;
			mwb_dat_i[31:16] = meshy*50+((10-meshx)*meshx)*3;
		end else if(mwb_adr_o[30]) begin
			//$display("%b %x write pixel at %d %d %x", mwb_we_o, mwb_adr_o, mwb_adr_o[29:2] % hres, mwb_adr_o[29:2] / hres, mwb_dat_o);
			if((px >= hres) | (py >= vres)) begin
				$display("Test failed: core attempted to write pixel (%d, %d) which is out of range", px, py);
				$image_close;
				$finish;
			end
			$image_set(px, py, mwb_dat_o);
		end else begin
			//$display("%b %x read pixel at %d %d %x", mwb_we_o, mwb_adr_o, mwb_adr_o[29:2] % hres, mwb_adr_o[29:2] / hres, mwb_dat_i);
			if((px >= hres) | (py >= vres)) begin
				$display("Test failed: core attempted to read pixel (%d, %d) which is out of range", px, py);
				$image_close;
				$finish;
			end
			$image_get(px, py, mwb_dat_i);
		end
	end
end

assign wb_cyc_i = 1'b1;

reg [31:0] i;

initial begin
	$display("Testing warp module");
	
	$image_open;
	
	#1 wb_clk_i = 1'b0;
	#1 wb_rst_i = 1'b1;
	#1 wb_rst_i = 1'b0;
	
	wb_we_i = 1'b0;
	wb_stb_i = 1'b0;
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000004;
	wb_dat_i = hres;
	wb_we_i = 1'b1;
	wb_stb_i = 1'b1;
	$display("hres\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000008;
	wb_dat_i = vres;
	$display("vres\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h0000000C;
	wb_dat_i = 32'h00000000;
	$display("inaddr\t%x", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000010;
	wb_dat_i = 32'h40000000;
	$display("outaddr\t%x", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000014;
	wb_dat_i = 255;
	$display("decay\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000018;
	wb_dat_i = 7;
	$display("mcountx\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h0000001C;
	wb_dat_i = 50;
	$display("msizex\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000020;
	wb_dat_i = 5;
	$display("mcounty\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000024;
	wb_dat_i = 50;
	$display("msizey\t%d", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000028;
	wb_dat_i = 32'h80000000;
	$display("maddr\t%x", wb_dat_i);
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	$display("Starting core");
	wb_adr_i = 32'h00000000;
	wb_dat_i = 32'h00000001;
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_we_i = 1'b0;
	wb_stb_i = 1'b0;
	#1 wb_clk_i = 1'b1;
	#1 wb_clk_i = 1'b0;
	
	wb_adr_i = 32'h00000000;
	wb_stb_i = 1'b1;
	
	i = 0;
	while(wb_dat_o[0]) begin
		i = i + 1;
		#1 wb_clk_i = 1'b1;
		#1 wb_clk_i = 1'b0;
	end
	
	$image_close;
	
	$display("Completed in %d cycles", i);
	
	$finish;
end

endmodule
