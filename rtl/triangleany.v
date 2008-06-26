/*
 * Triangle interpolation
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


/* No constraint on parameters */

module triangleany(
	input clk,
	input rst,
	
	/* coordinates are registered */
	input [10:0] xa,
	input [10:0] ya,
	input [10:0] ua,
	input [10:0] va,
	
	input [10:0] xb,
	input [10:0] yb,
	input [10:0] ub,
	input [10:0] vb,
	
	input [10:0] xc,
	input [10:0] yc,
	input [10:0] uc,
	input [10:0] vc,
	input load,
	
	output [10:0] x,
	output [10:0] y,
	output [10:0] u,
	output [10:0] v,
	input next,
	output ready,
	output finished
);

reg [3:0] state;
reg [3:0] next_state;
parameter IDLERUN = 0, CHOOSEA = 1, CHOOSEBC = 2, START= 3;

reg [10:0] xA;
reg [10:0] yA;
reg [10:0] uA;
reg [10:0] vA;

reg [10:0] xB;
reg [10:0] yB;
reg [10:0] uB;
reg [10:0] vB;

reg [10:0] xC;
reg [10:0] yC;
reg [10:0] uC;
reg [10:0] vC;

reg loadall;
reg swapAB;
reg swapAC;
reg swapBC;

reg triangleload;
wire triangleready;
wire trianglefinished;

triangle dut(
	.clk(clk),
	.rst(rst),
	
	.xa(xA),
	.ya(yA),
	.ua(uA),
	.va(vA),
	
	.xb(xB),
	.yb(yB),
	.ub(uB),
	.vb(vB),
	
	.xc(xC),
	.yc(yC),
	.uc(uC),
	.vc(vC),
	.load(triangleload),
	
	.x(x),
	.y(y),
	.u(u),
	.v(v),
	.next(next),
	.ready(triangleready),
	.finished(trianglefinished)
);

always @(posedge clk or posedge rst) begin
	if(rst) begin
		state <= IDLERUN;
		
		xA <= 0;
		yA <= 0;
		uA <= 0;
		vA <= 0;
		
		xB <= 0;
		yB <= 0;
		uB <= 0;
		vB <= 0;
		
		xC <= 0;
		yC <= 0;
		uC <= 0;
		vC <= 0;
	end else begin
		state <= next_state;
		if(loadall) begin
			xA <= xa;
			yA <= ya;
			uA <= ua;
			vA <= va;
			
			xB <= xb;
			yB <= yb;
			uB <= ub;
			vB <= vb;
			
			xC <= xc;
			yC <= yc;
			uC <= uc;
			vC <= vc;
		end else begin
			if(swapAB) begin
				xA <= xB;
				yA <= yB;
				uA <= uB;
				vA <= vB;
			
				xB <= xA;
				yB <= yA;
				uB <= uA;
				vB <= vA;
			end else if(swapAC) begin
				xA <= xC;
				yA <= yC;
				uA <= uC;
				vA <= vC;
			
				xC <= xA;
				yC <= yA;
				uC <= uA;
				vC <= vA;
			end else if(swapBC) begin
				xB <= xC;
				yB <= yC;
				uB <= uC;
				vB <= vC;
			
				xC <= xB;
				yC <= yB;
				uC <= uB;
				vC <= vB;
			end
		end
	end
end

assign ready = (state == IDLERUN) & triangleready;
assign finished = (state == IDLERUN) & trianglefinished;

always @(state or load or yA or yB or yC or xC or xB) begin
	/* XST does not generate a pure combinatorial function if next_state is
	 * not pre-affected, maybe because of the unused states.
	 */
	next_state = IDLERUN;

	triangleload = 1'b0;

	loadall = 1'b0;
	swapAB = 1'b0;
	swapAC = 1'b0;
	swapBC = 1'b0;
	
	
	case(state)
		IDLERUN: begin
			if(load) begin
				loadall = 1'b1;
				//$display("Loading triangle: (%d,%d), (%d,%d), (%d,%d)", xa, ya, xb, yb, xc, yc);
				//$display("Parameters:       (%d,%d), (%d,%d), (%d,%d)", ua, va, ub, vb, uc, vc);
				next_state = CHOOSEA;
			end else
				next_state = IDLERUN;
		end
		CHOOSEA: begin
			swapAB = (yB < yA) & (yB < yC);
			swapAC = (yC < yA) & (yC < yB);
			next_state = CHOOSEBC;
		end
		CHOOSEBC: begin
			swapBC = (xC < xB);
			next_state = START;
		end
		START: begin
			//$display("Ordered points: (%d,%d), (%d,%d), (%d,%d)", xA, yA, xB, yB, xC, yC);
			//$display("Parameters:     (%d,%d), (%d,%d), (%d,%d)", uA, vA, uB, vB, uC, vC);
			triangleload = 1'b1;
			next_state = IDLERUN;
		end
	endcase
end

endmodule
