/////////////////////////////////////////////////////////////////////
////                                                             ////
////  General Round Robin Arbiter                                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/wb_conmax/ ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

// Modified for Milkymist image warping
// Sebastien Bourdeauducq, 2008

module roundrobin3(clk, rst, req, gnt);

input		clk;
input		rst;
input	[2:0]	req;		// Req input
output	[2:0]	gnt; 		// Grant output

///////////////////////////////////////////////////////////////////////
//
// Parameters
//

parameter	[2:0]
                grant0 = 3'b001,
                grant1 = 3'b010,
                grant2 = 3'b100;

///////////////////////////////////////////////////////////////////////
//
// Local Registers and Wires
//

reg [2:0]	state, next_state;

///////////////////////////////////////////////////////////////////////
//
//  Misc Logic 
//

assign	gnt = state;

always@(posedge clk or posedge rst)
	if(rst)		state <= grant0;
	else		state <= next_state;

///////////////////////////////////////////////////////////////////////
//
// Next State Logic
//   - implements round robin arbitration algorithm
//   - switches grant if current req is dropped or next is asserted
//   - parks at last grant
//

always @(state or req) begin
	next_state = state;	// Default Keep State
	//$display("master [%b]: %b -> %b", req, state, next_state);
	case(state)		// synopsys parallel_case full_case
	   grant0:
		// if this req is dropped or next is asserted, check for other req's
		if(!req[0])
		   begin
			if(req[1])	next_state = grant1;
			else
			if(req[2])	next_state = grant2;
		   end
	   grant1:
		// if this req is dropped or next is asserted, check for other req's
		if(!req[1])
		   begin
			if(req[2])	next_state = grant2;
			else
			if(req[0])	next_state = grant0;
		   end
	   grant2:
		// if this req is dropped or next is asserted, check for other req's
		if(!req[2])
		   begin
			if(req[0])	next_state = grant0;
			else
			if(req[1])	next_state = grant1;
		   end
	endcase
end

endmodule
