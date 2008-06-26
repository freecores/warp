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

/* A must be the upper point (ya <= min(yb, yc))
 * B must be on the left of C (xb <= xc)
 */

module triangle(
	input clk,
	input rst,
	
	/* coordinates are not registered */
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
	
	output reg [10:0] x,
	output reg [10:0] y,
	output [10:0] u,
	output [10:0] v,
	input next,
	output reg ready,
	output reg finished
);

reg nextline;

wire readyAB;
wire readyAC;
wire readyBC;
wire finishedAB;
wire finishedAC;
wire finishedBC;

wire [10:0] xAB;
wire [10:0] xAC;
wire [10:0] xBC;

wire swapBC;
assign swapBC = yc < yb;

bresenham lineAB(
	.clk(clk),
	
	.x1(ya),
	.y1(xa),
	.x2(yb),
	.y2(xb),
	.load(load),
	.ready(readyAB),
	
	.x(),
	.y(xAB),
	.next(nextline),
	.finished(finishedAB)
);

bresenham lineAC(
	.clk(clk),
	
	.x1(ya),
	.y1(xa),
	.x2(yc),
	.y2(xc),
	.load(load),
	.ready(readyAC),
	
	.x(),
	.y(xAC),
	.next(nextline),
	.finished(finishedAC)
);

bresenham lineBC(
	.clk(clk),
	
	.x1(swapBC ? yc : yb),
	.y1(swapBC ? xc : xb),
	.x2(swapBC ? yb : yc),
	.y2(swapBC ? xb : xc),
	.load(load),
	.ready(readyBC),
	
	.x(),
	.y(xBC),
	.next(nextline & (finishedAB | finishedAC)),
	.finished(finishedBC)
);

wire [10:0] xmin;
wire [10:0] xmax;

assign xmin = finishedAB ? xBC : xAB;
assign xmax = (finishedAC & ~finishedAB)	// to handle horizontal BC
	| (finishedAB & finishedBC)		// to handle single-point BC with horizontal top line
	? xBC : xAC; 

wire readyuAB;
wire readyuAC;
wire readyuBC;
wire [10:0] uAB;
wire [10:0] uAC;
wire [10:0] uBC;

bresenham buAB(
	.clk(clk),
	
	.x1(ya),
	.y1(ua),
	.x2(yb),
	.y2(ub),
	.load(load),
	.ready(readyuAB),
	
	.x(),
	.y(uAB),
	.next(nextline),
	.finished()
);

bresenham buAC(
	.clk(clk),
	
	.x1(ya),
	.y1(ua),
	.x2(yc),
	.y2(uc),
	.load(load),
	.ready(readyuAC),
	
	.x(),
	.y(uAC),
	.next(nextline),
	.finished()
);

bresenham buBC(
	.clk(clk),
	
	.x1(swapBC ? yc : yb),
	.y1(swapBC ? uc : ub),
	.x2(swapBC ? yb : yc),
	.y2(swapBC ? ub : uc),
	.load(load),
	.ready(readyuBC),
	
	.x(),
	.y(uBC),
	.next(nextline & (finishedAB | finishedAC)),
	.finished()
);

wire [10:0] umin;
wire [10:0] umax;

assign umin = finishedAB ? uBC : uAB;
assign umax = (finishedAC & ~finishedAB) ? uBC : uAC;

wire readyvAB;
wire readyvAC;
wire readyvBC;
wire [10:0] vAB;
wire [10:0] vAC;
wire [10:0] vBC;

bresenham bvAB(
	.clk(clk),
	
	.x1(ya),
	.y1(va),
	.x2(yb),
	.y2(vb),
	.load(load),
	.ready(readyvAB),
	
	.x(),
	.y(vAB),
	.next(nextline),
	.finished()
);

bresenham bvAC(
	.clk(clk),
	
	.x1(ya),
	.y1(va),
	.x2(yc),
	.y2(vc),
	.load(load),
	.ready(readyvAC),
	
	.x(),
	.y(vAC),
	.next(nextline),
	.finished()
);

bresenham bvBC(
	.clk(clk),
	
	.x1(swapBC ? yc : yb),
	.y1(swapBC ? vc : vb),
	.x2(swapBC ? yb : yc),
	.y2(swapBC ? vb : vc),
	.load(load),
	.ready(readyvBC),
	
	.x(),
	.y(vBC),
	.next(nextline & (finishedAB | finishedAC)),
	.finished()
);

wire [10:0] vmin;
wire [10:0] vmax;

assign vmin = finishedAB ? vBC : vAB;
assign vmax = (finishedAC & ~finishedAB) ? vBC : vAC;

reg loadpixel;
reg nextpixel;

wire readybupixel;

bresenham bupixel(
	.clk(clk),
	
	.x1(xmin),
	.y1(umin),
	.x2(xmax),
	.y2(umax),
	.load(loadpixel),
	.ready(readybupixel),
	
	.x(),
	.y(u),
	.next(nextpixel),
	.finished()
);

wire readybvpixel;

bresenham bvpixel(
	.clk(clk),
	
	.x1(xmin),
	.y1(vmin),
	.x2(xmax),
	.y2(vmax),
	.load(loadpixel),
	.ready(readybvpixel),
	
	.x(),
	.y(v),
	.next(nextpixel),
	.finished()
);

reg [3:0] state;
reg [3:0] next_state;
parameter IDLE = 0, INITWAIT = 1, START_DRAWH = 2, UVWAIT = 3, DRAWH = 4;

reg [10:0] x_next;
reg [10:0] y_next;

always @(posedge clk or posedge rst) begin
	if(rst) begin
		state <= IDLE;
		x <= 0;
		y <= 0;
	end else begin
		state <= next_state;
		x <= x_next;
		y <= y_next;
	end
end

always @(state or load
	or readyAB or readyAC or readyBC
	or readyuAB or readyuAC or readyuBC
	or readyvAB or readyvAC or readyvBC
	or readybupixel or readybvpixel
	or xmin or xmax or finishedAB or finishedAC or finishedBC or next
	or xa or ya or x or y) begin
	
	/* XST does not generate a pure combinatorial function if next_state is
	 * not pre-affected, maybe because of the unused states.
	 */
	next_state = IDLE;
	
	x_next = x;
	y_next = y;
	finished = 1'b0;
	ready = 1'b0;
	nextline = 1'b0;
	loadpixel = 1'b0;
	nextpixel = 1'b0;

	case(state)
		IDLE: begin
			finished = 1'b1;
			ready = 1'b1;
			x_next = xa;
			y_next = ya;
			if(load)
				next_state = INITWAIT;
			else
				next_state = IDLE;
		end
		INITWAIT: begin
			if(readyAB & readyAC & readyBC
			 & readyuAB & readyuAC & readyuBC
			 & readyvAB & readyvAC & readyvBC)
				next_state = START_DRAWH;
			else
				next_state = INITWAIT;
		end
		START_DRAWH: begin
			//$display("LINE %d -> %d finishedAB %b finishedAC %b", xmin, xmax, finishedAB, finishedAC);
			//$display("xBC %d xAC %d", xBC, xAC);
			x_next = xmin;
			loadpixel = 1'b1;
			next_state = UVWAIT;
		end
		UVWAIT: begin
			if(readybupixel & readybvpixel)
				next_state = DRAWH;
			else
				next_state = UVWAIT;
		end
		DRAWH: begin
			ready = 1'b1;
			if(next) begin
				nextpixel = 1'b1;
				if(x == xmax) begin
					if(finishedAB & finishedAC & finishedBC)
						next_state = IDLE;
					else begin
						y_next = y + 1;
						nextline = 1'b1;
						next_state = START_DRAWH;
					end
				end else begin
					x_next = x + 1;
					next_state = DRAWH;
				end
			end else begin
				next_state = DRAWH;
			end
		end
	endcase
end

endmodule
