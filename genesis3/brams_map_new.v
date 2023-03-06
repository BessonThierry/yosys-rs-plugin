// Copyright (C) 2022 RapidSilicon
//
// In Genesis3, parameters MODE_BITS vectors have been reversed
// in order to match big endian behavior used by the fabric
// primitives DSP/BRAM (CASTORIP-121)

`define MODE_36 3'b110	// 36 or 32-bit
`define MODE_18 3'b010	// 18 or 16-bit
`define MODE_9  3'b100	// 9 or 8-bit
`define MODE_4  3'b001	// 4-bit
`define MODE_2  3'b011	// 32-bit
`define MODE_1  3'b101	// 32-bit

module \$__RS_FACTOR_BRAM36_TDP (...);
	parameter INIT = 0;
	parameter WIDTH = 1;
	
	parameter PORT_B_WR_EN_WIDTH = 1;
	parameter PORT_A_RD_INIT_VALUE = 0;
	parameter PORT_A_RD_SRST_VALUE = 1;
	
	parameter PORT_D_WR_EN_WIDTH = 1;
	parameter PORT_C_RD_INIT_VALUE = 0;
	parameter PORT_C_RD_SRST_VALUE = 1;

	localparam ABITS = 15;
	localparam CFG_ENABLE = 4;

    input CLK_C1;
    input CLK_C2;

	input 				PORT_A_CLK;
	input [ABITS-1:0] 		PORT_A_ADDR;
	output [WIDTH-1:0]		PORT_A_RD_DATA;
	input 				PORT_A_RD_EN;
	
	input 				PORT_B_CLK;
	input [ABITS-1:0] 		PORT_B_ADDR;
	input [WIDTH-1:0] 		PORT_B_WR_DATA;
	input [PORT_B_WR_EN_WIDTH-1:0]	PORT_B_WR_EN;

	input 				PORT_C_CLK;
	input [ABITS-1:0] 		PORT_C_ADDR;
	output [WIDTH-1:0]		PORT_C_RD_DATA;
	input 				PORT_C_RD_EN;
	
	input 				PORT_D_CLK;
	input [ABITS-1:0] 		PORT_D_ADDR;
	input [WIDTH-1:0] 		PORT_D_WR_DATA;
	input [PORT_B_WR_EN_WIDTH-1:0]	PORT_D_WR_EN;


	wire FLUSH1;
	wire FLUSH2;
	wire SPLIT;

	wire [CFG_ENABLE-1:PORT_B_WR_EN_WIDTH] B1EN_CMPL = {CFG_ENABLE-PORT_B_WR_EN_WIDTH{1'b0}};
	wire [CFG_ENABLE-1:PORT_D_WR_EN_WIDTH] D1EN_CMPL = {CFG_ENABLE-PORT_D_WR_EN_WIDTH{1'b0}};

	wire [CFG_ENABLE-1:0] B1EN = {B1EN_CMPL, PORT_B_WR_EN};
	wire [CFG_ENABLE-1:0] D1EN = {D1EN_CMPL, PORT_D_WR_EN};

	wire [35:WIDTH] B1DATA_CMPL;
	wire [35:WIDTH] D1DATA_CMPL;

	wire [35:0] A1DATA_TOTAL;
	wire [35:0] B1DATA_TOTAL;
	wire [35:0] C1DATA_TOTAL;
	wire [35:0] D1DATA_TOTAL;

	wire [ABITS-1:0] 		A_ADDR;
	wire [ABITS-1:0] 		B_ADDR;

	assign A_ADDR = PORT_A_RD_EN ? PORT_A_ADDR : (PORT_B_WR_EN ? PORT_B_ADDR : 15'd0);
	assign B_ADDR = PORT_C_RD_EN ? PORT_C_ADDR : (PORT_D_WR_EN ? PORT_D_ADDR : 15'd0);


	// Assign read/write data - handle special case for 9bit mode
	// parity bit for 9bit mode is placed in R/W port on bit #16
	case (WIDTH)
		9: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[16], A1DATA_TOTAL[7:0]};
			assign PORT_C_RD_DATA = {C1DATA_TOTAL[16], C1DATA_TOTAL[7:0]};
			assign B1DATA_TOTAL = {B1DATA_CMPL[35:17], PORT_B_WR_DATA[8], B1DATA_CMPL[16:9], PORT_B_WR_DATA[7:0]};
			assign D1DATA_TOTAL = {D1DATA_CMPL[35:17], PORT_D_WR_DATA[8], D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
		end
		default: begin
			assign PORT_A_RD_DATA = A1DATA_TOTAL[WIDTH-1:0];
			assign PORT_C_RD_DATA = C1DATA_TOTAL[WIDTH-1:0];
			assign B1DATA_TOTAL = {B1DATA_CMPL, PORT_B_WR_DATA};
			assign D1DATA_TOTAL = {D1DATA_CMPL, PORT_D_WR_DATA};
		end
	endcase

	case (WIDTH)
		1: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_1, `MODE_1, `MODE_1, `MODE_1, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_1, `MODE_1, `MODE_1, `MODE_1, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		2: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_2, `MODE_2, `MODE_2, `MODE_2, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_2, `MODE_2, `MODE_2, `MODE_2, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		4: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_4, `MODE_4, `MODE_4, `MODE_4, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_4, `MODE_4, `MODE_4, `MODE_4, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		8, 9: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_9, `MODE_9, `MODE_9, `MODE_9, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_9, `MODE_9, `MODE_9, `MODE_9, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		16, 18: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_18, `MODE_18, `MODE_18, `MODE_18, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_18, `MODE_18, `MODE_18, `MODE_18, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		32, 36: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end
		default: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end
	endcase


	assign SPLIT = 1'b0;
	assign FLUSH1 = 1'b0;
	assign FLUSH2 = 1'b0;
    
	RS_TDP36K #(
        .INIT_i(INIT)
        ) _TECHMAP_REPLACE_ (
		.WDATA_A1(B1DATA_TOTAL[17:0]),
		.WDATA_A2(B1DATA_TOTAL[35:18]),
		.RDATA_A1(A1DATA_TOTAL[17:0]),
		.RDATA_A2(A1DATA_TOTAL[35:18]),
		.ADDR_A1(A_ADDR),
		.ADDR_A2(A_ADDR),
		.CLK_A1(PORT_A_CLK),
		.CLK_A2(PORT_A_CLK),
		.REN_A1(PORT_A_RD_EN),
		.REN_A2(PORT_A_RD_EN),
		.WEN_A1(PORT_B_WR_EN),
		.WEN_A2(PORT_B_WR_EN),
		.BE_A1({B1EN[1],B1EN[0]}),
		.BE_A2({B1EN[3],B1EN[2]}),

		.WDATA_B1(D1DATA_TOTAL[17:0]),
		.WDATA_B2(D1DATA_TOTAL[35:18]),
		.RDATA_B1(C1DATA_TOTAL[17:0]),
		.RDATA_B2(C1DATA_TOTAL[35:18]),
		.ADDR_B1(B_ADDR),
		.ADDR_B2(B_ADDR),
		.CLK_B1(PORT_C_CLK),
		.CLK_B2(PORT_C_CLK),
		.REN_B1(PORT_C_RD_EN),
		.REN_B2(PORT_C_RD_EN),
		.WEN_B1(PORT_D_WR_EN),
		.WEN_B2(PORT_D_WR_EN),
		.BE_B1({D1EN[1],D1EN[0]}),
		.BE_B2({D1EN[3],D1EN[2]}),

		.FLUSH1(FLUSH1),
		.FLUSH2(FLUSH2)
	);
endmodule

// ------------------------------------------------------------------------

module \$__RS_FACTOR_BRAM18_TDP (...);
	parameter INIT = 0;
	parameter WIDTH = 1;
	
	parameter PORT_B_WR_EN_WIDTH = 1;
	parameter PORT_A_RD_INIT_VALUE = 0;
	parameter PORT_A_RD_SRST_VALUE = 1;
	
	parameter PORT_D_WR_EN_WIDTH = 1;
	parameter PORT_C_RD_INIT_VALUE = 0;
	parameter PORT_C_RD_SRST_VALUE = 1;

	localparam ABITS = 14;
	localparam CLKPOL2 = 1;
	localparam CLKPOL3 = 1;
    
    input CLK_C1;
    input CLK_C2;
	
    input 				PORT_A_CLK;
	input [ABITS-1:0] 		PORT_A_ADDR;
	output [WIDTH-1:0]		PORT_A_RD_DATA;
	input 				PORT_A_RD_EN;
	
	input 				PORT_B_CLK;
	input [ABITS-1:0] 		PORT_B_ADDR;
	input [WIDTH-1:0] 		PORT_B_WR_DATA;
	input [PORT_B_WR_EN_WIDTH-1:0]	PORT_B_WR_EN;
	
    input 				PORT_C_CLK;
	input [ABITS-1:0] 		PORT_C_ADDR;
	output [WIDTH-1:0]		PORT_C_RD_DATA;
	input 				PORT_C_RD_EN;
	
	input 				PORT_D_CLK;
	input [ABITS-1:0] 		PORT_D_ADDR;
	input [WIDTH-1:0] 		PORT_D_WR_DATA;
	input [PORT_D_WR_EN_WIDTH-1:0]	PORT_D_WR_EN;

	BRAM2x18_TDP #(
		.CFG_DBITS(WIDTH),
		.CFG_ENABLE_B(PORT_B_WR_EN_WIDTH),
		.CFG_ENABLE_D(PORT_D_WR_EN_WIDTH),
		.CLKPOL2(CLKPOL2),
		.CLKPOL3(CLKPOL3),
		.INIT0(INIT)
	) _TECHMAP_REPLACE_ (
		.A1ADDR(PORT_A_ADDR),
		.A1DATA(PORT_A_RD_DATA),
		.A1EN(PORT_A_RD_EN),
		.B1ADDR(PORT_B_ADDR),
		.B1DATA(PORT_B_WR_DATA),
		.B1EN(PORT_B_WR_EN),
		.CLK1(PORT_A_CLK),

		.C1ADDR(PORT_C_ADDR),
		.C1DATA(PORT_C_RD_DATA),
		.C1EN(PORT_C_RD_EN),
		.D1ADDR(PORT_D_ADDR),
		.D1DATA(PORT_D_WR_DATA),
		.D1EN(PORT_D_WR_EN),
		.CLK2(PORT_C_CLK),

		.E1ADDR(),
		.E1DATA(),
		.E1EN(),
		.F1ADDR(),
		.F1DATA(),
		.F1EN(),
		.CLK3(),

		.G1ADDR(),
		.G1DATA(),
		.G1EN(),
		.H1ADDR(),
		.H1DATA(),
		.H1EN(),
		.CLK4()
	);
endmodule

module \$__RS_FACTOR_BRAM18_SDP (...);
	parameter WIDTH = 1; 
    parameter PORT_B_WR_EN_WIDTH = 4;
    parameter PORT_A_RD_INIT_VALUE = 1;

    parameter [18431:0] INIT = 18432'bx;

    localparam CLKPOL2 = 1;
	localparam CLKPOL3 = 1;
    localparam ABITS = 14;

    input PORT_A_CLK;
	input PORT_B_CLK;

	input [ABITS-1:0] PORT_A_ADDR;
	output [WIDTH-1:0] PORT_A_RD_DATA;
	input PORT_A_RD_EN;

	input [ABITS-1:0] PORT_B_ADDR;
	input [WIDTH-1:0] PORT_B_WR_DATA;
	input [PORT_B_WR_EN_WIDTH-1:0] PORT_B_WR_EN;

	BRAM2x18_SDP #(
		.CFG_DBITS(WIDTH),
		.CFG_ENABLE_B(PORT_B_WR_EN_WIDTH),
		.CLKPOL2(CLKPOL2),
		.CLKPOL3(CLKPOL3),
		.INIT0(INIT)
	) _TECHMAP_REPLACE_ (
		.A1ADDR(PORT_A_ADDR),
		.A1DATA(PORT_A_RD_DATA),
		.A1EN(PORT_A_RD_EN),
		.CLK1(PORT_A_CLK),

		.B1ADDR(PORT_B_ADDR),
		.B1DATA(PORT_B_WR_DATA),
		.B1EN(PORT_B_WR_EN),
		.CLK2(PORT_B_CLK)
	);
endmodule

module \$__RS_FACTOR_BRAM36_SDP (...);
	parameter WIDTH = 1;
	parameter PORT_B_WR_EN_WIDTH = 4;
    parameter PORT_A_RD_INIT_VALUE = 1;

	parameter [36863:0] INIT = 36864'bx;
	
    localparam ABITS = 15;

	input PORT_A_CLK;
	input PORT_B_CLK;

	input [ABITS-1:0] PORT_A_ADDR;
	output [WIDTH-1:0] PORT_A_RD_DATA;
	input PORT_A_RD_EN;

	input [ABITS-1:0] PORT_B_ADDR;
	input [WIDTH-1:0] PORT_B_WR_DATA;
	input [PORT_B_WR_EN_WIDTH-1:0] PORT_B_WR_EN;

	wire [35:0] DOBDO;
	wire [35:WIDTH] A1DATA_CMPL;
	wire [35:WIDTH] B1DATA_CMPL;
	wire [35:0] A1DATA_TOTAL;
	wire [35:0] B1DATA_TOTAL;

	wire FLUSH1;
	wire FLUSH2;

	// Assign read/write data - handle special case for 9bit mode
	// parity bit for 9bit mode is placed in R/W port on bit #16
	case (WIDTH)
		9: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[16], A1DATA_TOTAL[7:0]};
			assign B1DATA_TOTAL = {B1DATA_CMPL[35:17], PORT_B_WR_DATA[8], B1DATA_CMPL[16:9], PORT_B_WR_DATA[7:0]};
		end
		default: begin
			assign PORT_A_RD_DATA = A1DATA_TOTAL[WIDTH-1:0];
			assign B1DATA_TOTAL = {B1DATA_CMPL, PORT_B_WR_DATA};
		end
	endcase

	case (WIDTH)
		1: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_1, `MODE_1, `MODE_1, `MODE_1, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_1, `MODE_1, `MODE_1, `MODE_1, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		2: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_2, `MODE_2, `MODE_2, `MODE_2, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_2, `MODE_2, `MODE_2, `MODE_2, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		4: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_4, `MODE_4, `MODE_4, `MODE_4, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_4, `MODE_4, `MODE_4, `MODE_4, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		8, 9: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_9, `MODE_9, `MODE_9, `MODE_9, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_9, `MODE_9, `MODE_9, `MODE_9, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		16, 18: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_18, `MODE_18, `MODE_18, `MODE_18, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_18, `MODE_18, `MODE_18, `MODE_18, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end

		32, 36: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end
		default: begin
			defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 12'b010100000000, 12'b010100000000, 1'd0,
				`MODE_36, `MODE_36, `MODE_36, `MODE_36, 4'd0, 11'b01010000000, 11'b01010000000, 1'b0
			};
		end
	endcase

	assign FLUSH1 = 1'b0;
	assign FLUSH2 = 1'b0;

	RS_TDP36K #(
        .INIT_i(INIT)
         ) _TECHMAP_REPLACE_ (
		.WDATA_A1(18'h3FFFF),
		.WDATA_A2(18'h3FFFF),
		.RDATA_A1(A1DATA_TOTAL[17:0]),
		.RDATA_A2(A1DATA_TOTAL[35:18]),
		.ADDR_A1(PORT_A_ADDR),
		.ADDR_A2(PORT_A_ADDR),
		.CLK_A1(PORT_A_CLK),
		.CLK_A2(PORT_A_CLK),
		.REN_A1(PORT_A_RD_EN),
		.REN_A2(PORT_A_RD_EN),
		.WEN_A1(1'b0),
		.WEN_A2(1'b0),
		.BE_A1({PORT_A_RD_EN, PORT_A_RD_EN}),
		.BE_A2({PORT_A_RD_EN, PORT_A_RD_EN}),

		.WDATA_B1(B1DATA_TOTAL[17:0]),
		.WDATA_B2(B1DATA_TOTAL[35:18]),
		.RDATA_B1(DOBDO[17:0]),
		.RDATA_B2(DOBDO[35:18]),
		.ADDR_B1(PORT_B_ADDR),
		.ADDR_B2(PORT_B_ADDR),
		.CLK_B1(PORT_B_CLK),
		.CLK_B2(PORT_B_CLK),
		.REN_B1(1'b0),
		.REN_B2(1'b0),
		.WEN_B1(PORT_B_WR_EN[0]),
		.WEN_B2(PORT_B_WR_EN[0]),
		.BE_B1(PORT_B_WR_EN[1:0]),
		.BE_B2(PORT_B_WR_EN[3:2]),

		.FLUSH1(FLUSH1),
		.FLUSH2(FLUSH2)
	);
endmodule