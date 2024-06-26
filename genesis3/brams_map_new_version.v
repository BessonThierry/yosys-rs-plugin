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
parameter [32767:0] INIT = {32768{1'b0}};
parameter [4095:0] INIT_PARITY = {4096{1'b0}};
parameter PORT_B_Parity =0;
parameter PORT_D_Parity =0;
parameter WIDTH = 1;
parameter PORT_D_DATA_WIDTH = 1;
parameter PORT_B_DATA_WIDTH = 1;
parameter PORT_A_DATA_WIDTH = 1;
parameter PORT_C_DATA_WIDTH = 1;

parameter PORT_D_WIDTH = 1;
parameter PORT_C_WIDTH = 1;

parameter PORT_B_WIDTH = 1;
parameter PORT_A_WIDTH = 1;

parameter PORT_B_WR_BE_WIDTH = 1;
parameter PORT_A_RD_SRST_VALUE = 1;

parameter PORT_D_WR_BE_WIDTH = 1;
parameter PORT_C_RD_SRST_VALUE = 1;

localparam ABITS = 15;
localparam CFG_ENABLE = 4;

localparam [2:0]PORT_A_MODE = (PORT_A_WIDTH == 1)?`MODE_1:(PORT_A_WIDTH == 2)?`MODE_2:(PORT_A_WIDTH == 4)?`MODE_4:(PORT_A_WIDTH ==8)?`MODE_9:(PORT_A_WIDTH ==9)?`MODE_9:(PORT_A_WIDTH ==16)?`MODE_18:(PORT_A_WIDTH ==18)?`MODE_18:`MODE_36;
localparam [2:0]PORT_B_MODE = (PORT_B_WIDTH == 1)?`MODE_1:(PORT_B_WIDTH == 2)?`MODE_2:(PORT_B_WIDTH == 4)?`MODE_4:(PORT_B_WIDTH ==8)?`MODE_9:(PORT_B_WIDTH ==9)?`MODE_9:(PORT_B_WIDTH ==16)?`MODE_18:(PORT_B_WIDTH ==18)?`MODE_18:`MODE_36;
localparam [2:0]PORT_C_MODE = (PORT_C_WIDTH == 1)?`MODE_1:(PORT_C_WIDTH == 2)?`MODE_2:(PORT_C_WIDTH == 4)?`MODE_4:(PORT_C_WIDTH ==8)?`MODE_9:(PORT_C_WIDTH ==9)?`MODE_9:(PORT_C_WIDTH ==16)?`MODE_18:(PORT_C_WIDTH ==18)?`MODE_18:`MODE_36;
localparam [2:0]PORT_D_MODE = (PORT_D_WIDTH == 1)?`MODE_1:(PORT_D_WIDTH == 2)?`MODE_2:(PORT_D_WIDTH == 4)?`MODE_4:(PORT_D_WIDTH ==8)?`MODE_9:(PORT_D_WIDTH ==9)?`MODE_9:(PORT_D_WIDTH ==16)?`MODE_18:(PORT_D_WIDTH ==18)?`MODE_18:`MODE_36;

input CLK_C1;
input CLK_C2;

input 				PORT_A_CLK;
input [ABITS-1:0] 		PORT_A_ADDR;
output [PORT_A_WIDTH-1:0]		PORT_A_RD_DATA;
input 				PORT_A_RD_EN;

input 				PORT_B_CLK;
input [ABITS-1:0] 		PORT_B_ADDR;
input [PORT_B_WIDTH-1:0] 		PORT_B_WR_DATA;
input 				PORT_B_WR_EN;
input [PORT_B_WR_BE_WIDTH-1:0]	PORT_B_WR_BE;

input 				PORT_C_CLK;
input [ABITS-1:0] 		PORT_C_ADDR;
output [PORT_C_WIDTH-1:0]		PORT_C_RD_DATA;
input 				PORT_C_RD_EN;

input 				PORT_D_CLK;
input [ABITS-1:0] 		PORT_D_ADDR;
input [PORT_D_WIDTH-1:0] 		PORT_D_WR_DATA;
input 				PORT_D_WR_EN;
input [PORT_B_WR_BE_WIDTH-1:0]	PORT_D_WR_BE;


wire FLUSH1;
wire FLUSH2;
wire SPLIT;

wire [CFG_ENABLE-1:PORT_B_WR_BE_WIDTH] B1EN_CMPL = {CFG_ENABLE-PORT_B_WR_BE_WIDTH{1'b0}};
wire [CFG_ENABLE-1:PORT_D_WR_BE_WIDTH] D1EN_CMPL = {CFG_ENABLE-PORT_D_WR_BE_WIDTH{1'b0}};

wire [CFG_ENABLE-1:0] B1EN = {B1EN_CMPL, PORT_B_WR_BE};
wire [CFG_ENABLE-1:0] D1EN = {D1EN_CMPL, PORT_D_WR_BE};

wire [35:PORT_B_WIDTH] B1DATA_CMPL;
wire [35:PORT_D_WIDTH] D1DATA_CMPL;

wire [35:0] A1DATA_TOTAL;
wire [35:0] B1DATA_TOTAL;
wire [35:0] C1DATA_TOTAL;
wire [35:0] D1DATA_TOTAL;

wire [ABITS-1:0] 		A_ADDR;
wire [ABITS-1:0] 		B_ADDR;

// assign A_ADDR = PORT_A_RD_EN ? PORT_A_ADDR : (PORT_B_WR_EN ? PORT_B_ADDR : 15'd0);
// assign B_ADDR = PORT_C_RD_EN ? PORT_C_ADDR : (PORT_D_WR_EN ? PORT_D_ADDR : 15'd0);

// Awais: If address for read and write ports are same then extra logic for adress collision is not needed
assign A_ADDR = PORT_A_ADDR == PORT_B_ADDR ? PORT_A_ADDR : PORT_A_RD_EN ? PORT_A_ADDR : (PORT_B_WR_EN ? PORT_B_ADDR : 15'd0);
assign B_ADDR = PORT_C_ADDR == PORT_D_ADDR ? PORT_C_ADDR : PORT_C_RD_EN ? PORT_C_ADDR : (PORT_D_WR_EN ? PORT_D_ADDR : 15'd0);

// Assign read/write data - handle special case for 9bit mode
// parity bit for 9bit mode is placed in R/W port on bit #16


// PORT A
case (PORT_A_WIDTH)
	9: begin
		case (PORT_A_DATA_WIDTH)
		9: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
		end
		18: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
		end
		32,36: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
		end
		default: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
		end
	endcase
	end
	18: begin
		//assign A1DATA_TOTAL = {A1DATA_TOTAL[35:18],PORT_A_RD_DATA[17], PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		case (PORT_A_DATA_WIDTH)
			18: begin
				assign A1DATA_TOTAL = {A1DATA_TOTAL[35],A1DATA_TOTAL[26],PORT_A_RD_DATA[17],PORT_A_RD_DATA[8],A1DATA_TOTAL[34:27],A1DATA_TOTAL[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
			end
			32,36: begin
				assign {A1DATA_TOTAL[33],A1DATA_TOTAL[32],A1DATA_TOTAL[15:0]} = {PORT_A_RD_DATA[17],PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
			end
			default: begin
				assign PORT_A_RD_DATA = {A1DATA_TOTAL[33],A1DATA_TOTAL[32],A1DATA_TOTAL[15:0]};
			end
		endcase
	end
	36: begin
		//assign A1DATA_TOTAL = {PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[17], PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		case(PORT_A_DATA_WIDTH)
			36:begin
				assign A1DATA_TOTAL = {PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
			end
			27:begin
				assign A1DATA_TOTAL = {PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
			end
			default: begin
				assign A1DATA_TOTAL = (!PORT_B_Parity)? PORT_A_RD_DATA[PORT_A_WIDTH-1:0]:
									({PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]});
			end
		endcase
	end
	default: begin
		assign PORT_A_RD_DATA = A1DATA_TOTAL[PORT_A_WIDTH-1:0];
		
	end
endcase

// PORT B
case (PORT_B_WIDTH)
	9: begin	
		case (PORT_B_DATA_WIDTH)
			9:begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			18:begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end 
			32,36: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			default: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,B1DATA_CMPL[16:9], PORT_B_WR_DATA[7:0]};
			end
		endcase
	end
	18: begin
		//assign B1DATA_TOTAL = {B1DATA_CMPL[35:18], PORT_B_WR_DATA[17], PORT_B_WR_DATA[8], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		case (PORT_B_DATA_WIDTH)
			18: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			32,36: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			default: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[34], PORT_B_WR_DATA[17], PORT_B_WR_DATA[16],B1DATA_CMPL[33:26],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[15:8], PORT_B_WR_DATA[7:0]};
			end
		endcase
	end
	36: begin
		//assign B1DATA_TOTAL = {PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		case(PORT_B_DATA_WIDTH)
		27:begin
			assign B1DATA_TOTAL = {PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		end
		36:begin
			assign B1DATA_TOTAL = {PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		end
		default: begin
			assign B1DATA_TOTAL =(!PORT_B_Parity)? {B1DATA_CMPL, PORT_B_WR_DATA}:
								({PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]});
		end
	endcase
	end
	default: begin
		assign B1DATA_TOTAL = {B1DATA_CMPL, PORT_B_WR_DATA};
		
	end
endcase

// PORT C
case (PORT_C_WIDTH)
	9: begin
		//assign PORT_C_RD_DATA = {C1DATA_TOTAL[16], C1DATA_TOTAL[7:0]};
		case (PORT_C_DATA_WIDTH)
			9: begin
				assign PORT_C_RD_DATA = {C1DATA_TOTAL[32], C1DATA_TOTAL[7:0]};
			end
			18: begin
				assign PORT_C_RD_DATA = {C1DATA_TOTAL[32], C1DATA_TOTAL[7:0]};
			end
			32,36: begin
				assign PORT_C_RD_DATA = {C1DATA_TOTAL[32], C1DATA_TOTAL[7:0]};
			end
			default: begin
				assign PORT_C_RD_DATA = {C1DATA_TOTAL[32], C1DATA_TOTAL[7:0]};
			end
		endcase
	end
	18: begin
		//assign C1DATA_TOTAL = {C1DATA_TOTAL[35:18],PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
		case (PORT_C_DATA_WIDTH)
		18	:begin
			assign C1DATA_TOTAL = {C1DATA_TOTAL[35], C1DATA_TOTAL[26], PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], C1DATA_TOTAL[34:27], C1DATA_TOTAL[25:18], PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
			end 
		32,36: begin
				assign {C1DATA_TOTAL[33],C1DATA_TOTAL[32],C1DATA_TOTAL[15:0]} = {PORT_C_RD_DATA[17],PORT_C_RD_DATA[8],PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
			end
		default: begin
				assign PORT_C_RD_DATA = {C1DATA_TOTAL[33],C1DATA_TOTAL[32],C1DATA_TOTAL[15:0]};
			end
		endcase
	end
	36: begin
		//assign C1DATA_TOTAL = {PORT_C_RD_DATA[35], PORT_C_RD_DATA[26], PORT_C_RD_DATA[34:27], PORT_C_RD_DATA[25:18],PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
		case(PORT_C_DATA_WIDTH)
		27:begin
			assign C1DATA_TOTAL = {PORT_C_RD_DATA[35], PORT_C_RD_DATA[26],PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], PORT_C_RD_DATA[34:27], PORT_C_RD_DATA[25:18], PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
		end
		36:begin
			assign C1DATA_TOTAL = {PORT_C_RD_DATA[35], PORT_C_RD_DATA[26],PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], PORT_C_RD_DATA[34:27], PORT_C_RD_DATA[25:18], PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]};
		end
		default: begin
			assign C1DATA_TOTAL = (!PORT_D_Parity)? PORT_C_RD_DATA[PORT_C_WIDTH-1:0]:
			({PORT_C_RD_DATA[35],PORT_C_RD_DATA[26], PORT_C_RD_DATA[17], PORT_C_RD_DATA[8], PORT_C_RD_DATA[34:27], PORT_C_RD_DATA[25:18],PORT_C_RD_DATA[16:9], PORT_C_RD_DATA[7:0]});
		end
	endcase
	end
	default: begin
		assign PORT_C_RD_DATA = C1DATA_TOTAL[PORT_C_WIDTH-1:0];
		
	end
endcase

// PORT D
case (PORT_D_WIDTH)
	9: begin
		//assign D1DATA_TOTAL = {D1DATA_CMPL[35:17], PORT_D_WR_DATA[8], D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
		case (PORT_D_DATA_WIDTH)
			9: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35], D1DATA_CMPL[26], D1DATA_CMPL[17], PORT_D_WR_DATA[8], D1DATA_CMPL[34:27], D1DATA_CMPL[25:18], D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
			end
			18: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35], D1DATA_CMPL[26], D1DATA_CMPL[17], PORT_D_WR_DATA[8], D1DATA_CMPL[34:27], D1DATA_CMPL[25:18], D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
			end
			32,36: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35], D1DATA_CMPL[26], D1DATA_CMPL[17], PORT_D_WR_DATA[8], D1DATA_CMPL[34:27], D1DATA_CMPL[25:18], D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
			end
			default: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35],D1DATA_CMPL[26], D1DATA_CMPL[17], PORT_D_WR_DATA[8],D1DATA_CMPL[34:27],D1DATA_CMPL[25:18] ,D1DATA_CMPL[16:9], PORT_D_WR_DATA[7:0]};
			end
		endcase
	end
	18: begin
		//assign D1DATA_TOTAL = {D1DATA_CMPL[35:18], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
		case (PORT_D_DATA_WIDTH)
			18:begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35], D1DATA_CMPL[26], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8], D1DATA_CMPL[34:27], D1DATA_CMPL[25:18], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
			end 
			32,36: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35],D1DATA_CMPL[26], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8],D1DATA_CMPL[34:27],D1DATA_CMPL[25:18] ,PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
			end
			default: begin
				assign D1DATA_TOTAL = {D1DATA_CMPL[35],D1DATA_CMPL[34], PORT_D_WR_DATA[17], PORT_D_WR_DATA[16],D1DATA_CMPL[33:26],D1DATA_CMPL[25:18] ,PORT_D_WR_DATA[15:8], PORT_D_WR_DATA[7:0]};
			end
		endcase
	end
	36: begin
		//assign D1DATA_TOTAL = {PORT_D_WR_DATA[35], PORT_D_WR_DATA[26], PORT_D_WR_DATA[34:27], PORT_D_WR_DATA[25:18], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
		case(PORT_D_DATA_WIDTH)
		27:begin
			assign D1DATA_TOTAL = {PORT_D_WR_DATA[35], PORT_D_WR_DATA[26], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8], PORT_D_WR_DATA[34:27], PORT_D_WR_DATA[25:18], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
		end
		36:begin
			assign D1DATA_TOTAL = {PORT_D_WR_DATA[35], PORT_D_WR_DATA[26], PORT_D_WR_DATA[17], PORT_D_WR_DATA[8], PORT_D_WR_DATA[34:27], PORT_D_WR_DATA[25:18], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]};
		end
		default: begin
			assign D1DATA_TOTAL = (!PORT_D_Parity)? {D1DATA_CMPL, PORT_D_WR_DATA}:
			({PORT_D_WR_DATA[35], PORT_D_WR_DATA[26],PORT_D_WR_DATA[17], PORT_D_WR_DATA[8],PORT_D_WR_DATA[34:27],PORT_D_WR_DATA[25:18], PORT_D_WR_DATA[16:9], PORT_D_WR_DATA[7:0]});
		end
	endcase
	end
	default: begin
		assign D1DATA_TOTAL = {D1DATA_CMPL, PORT_D_WR_DATA};
		
	end
endcase



assign SPLIT = 1'b0;
assign FLUSH1 = 1'b0;
assign FLUSH2 = 1'b0;

TDP_RAM36K #(
  .INIT (INIT), // Initial Contents of memory
  .INIT_PARITY (INIT_PARITY), // Initial Contents of memory
  .WRITE_WIDTH_A (PORT_B_WIDTH), // Write data width on port A (1-36)
  .READ_WIDTH_A (PORT_A_WIDTH), // Read data width on port A (1-36)
  .WRITE_WIDTH_B (PORT_D_WIDTH), // Write data width on port B (1-36)
  .READ_WIDTH_B (PORT_C_WIDTH) // Read data width on port B (1-36)
) _TECHMAP_REPLACE_ (
  .WEN_A(PORT_B_WR_EN), // Write-enable port A
  .WEN_B(PORT_D_WR_EN), // Write-enable port B
  .REN_A(PORT_A_RD_EN), // Read-enable port A
  .REN_B(PORT_C_RD_EN), // Read-enable port B
  .CLK_A(PORT_A_CLK), // Clock port A
  .CLK_B(PORT_C_CLK), // Clock port B
  .BE_A(B1EN), // Byte-write enable port A
  .BE_B(D1EN), // Byte-write enable port B
  .ADDR_A(A_ADDR), // Address port A, align MSBs and connect unused MSBs to logic 0
  .ADDR_B(B_ADDR), // Address port B, align MSBs and connect unused MSBs to logic 0
  .WDATA_A({B1DATA_TOTAL[31:0]}), // Write data port A
  .WPARITY_A({B1DATA_TOTAL[35], B1DATA_TOTAL[34], B1DATA_TOTAL[33], B1DATA_TOTAL[32]}), // Write parity data port A
  .RDATA_A ({A1DATA_TOTAL[31:0]}), // Read data port A
  .RPARITY_A ({A1DATA_TOTAL[35], A1DATA_TOTAL[34], A1DATA_TOTAL[33], A1DATA_TOTAL[32]}), // Read parity port A
  .WDATA_B({D1DATA_TOTAL[31:0]}), // Write data port B
  .WPARITY_B({D1DATA_TOTAL[35], D1DATA_TOTAL[34], D1DATA_TOTAL[33], D1DATA_TOTAL[32]}), // Write parity port B
  .RDATA_B ({C1DATA_TOTAL[31:0]}), // Read data port B
  .RPARITY_B ({C1DATA_TOTAL[35], C1DATA_TOTAL[34], C1DATA_TOTAL[33], C1DATA_TOTAL[32]}) // Read parity port B
);
endmodule

// ------------------------------------------------------------------------

module \$__RS_FACTOR_BRAM18_TDP (...);
	parameter [32767:0] INIT = {32768{1'b0}};
	parameter [2047:0] INIT_PARITY = {2048{1'b0}};
	//parameter WIDTH = 1;

	parameter PORT_D_WIDTH = 1;
    parameter PORT_C_WIDTH = 1;
	
	parameter PORT_D_DATA_WIDTH = 1;
	parameter PORT_C_DATA_WIDTH = 1;
	
    parameter PORT_B_WIDTH = 1;
    parameter PORT_A_WIDTH = 1;
	
	parameter PORT_B_DATA_WIDTH = 1;
	parameter PORT_A_DATA_WIDTH = 1;

	parameter PORT_B_WR_BE_WIDTH = 1;
	parameter PORT_A_RD_SRST_VALUE = 1;
	
	parameter PORT_D_WR_BE_WIDTH = 1;
	parameter PORT_C_RD_SRST_VALUE = 1;

	localparam ABITS = 14;
	localparam CLKPOL2 = 1;
	localparam CLKPOL3 = 1;
    
    input CLK_C1;
    input CLK_C2;
	
    input 				PORT_A_CLK;
	input [ABITS-1:0] 		PORT_A_ADDR;
	output [PORT_A_WIDTH-1:0]		PORT_A_RD_DATA;
	input 				PORT_A_RD_EN;
	
	input 				PORT_B_CLK;
	input [ABITS-1:0] 		PORT_B_ADDR;
	input [PORT_B_WIDTH-1:0] 		PORT_B_WR_DATA;
	input 				PORT_B_WR_EN;
	input [PORT_B_WR_BE_WIDTH-1:0]	PORT_B_WR_BE;
	
    input 				PORT_C_CLK;
	input [ABITS-1:0] 		PORT_C_ADDR;
	output [PORT_C_WIDTH-1:0]		PORT_C_RD_DATA;
	input 				PORT_C_RD_EN;
	
	input 				PORT_D_CLK;
	input [ABITS-1:0] 		PORT_D_ADDR;
	input [PORT_D_WIDTH-1:0] 		PORT_D_WR_DATA;
	input 				PORT_D_WR_EN;
	input [PORT_D_WR_BE_WIDTH-1:0]	PORT_D_WR_BE;

	BRAM2x18_TDP #(
		.CFG_DBITS(),
		.PORT_A_WIDTH(PORT_A_WIDTH),
		.PORT_B_WIDTH(PORT_B_WIDTH),
		.PORT_C_WIDTH(PORT_C_WIDTH),
		.PORT_D_WIDTH(PORT_D_WIDTH),
		.PORT_A_DATA_WIDTH(PORT_A_DATA_WIDTH),
		.PORT_B_DATA_WIDTH(PORT_B_DATA_WIDTH),
		.PORT_C_DATA_WIDTH(PORT_C_DATA_WIDTH),
		.PORT_D_DATA_WIDTH(PORT_D_DATA_WIDTH),
		.CFG_ENABLE_B(PORT_B_WR_BE_WIDTH),
		.CFG_ENABLE_D(PORT_D_WR_BE_WIDTH),
		.CLKPOL2(CLKPOL2),
		.CLKPOL3(CLKPOL3),
		.INIT0(INIT),
		.INIT0_PARITY(INIT_PARITY)
	) _TECHMAP_REPLACE_ (
		.A1ADDR(PORT_A_ADDR),
		.A1DATA(PORT_A_RD_DATA),
		.A1EN(PORT_A_RD_EN),
		.B1ADDR(PORT_B_ADDR),
		.B1DATA(PORT_B_WR_DATA),
		.B1EN(PORT_B_WR_EN),
		.B1BE(PORT_B_WR_BE),
		.CLK1(PORT_A_CLK),

		.C1ADDR(PORT_C_ADDR),
		.C1DATA(PORT_C_RD_DATA),
		.C1EN(PORT_C_RD_EN),
		.D1ADDR(PORT_D_ADDR),
		.D1DATA(PORT_D_WR_DATA),
		.D1EN(PORT_D_WR_EN),
		.D1BE(PORT_D_WR_BE),
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
	//parameter WIDTH = 1; 
    parameter PORT_A_WIDTH=1;
	parameter PORT_B_WIDTH=1;

	parameter PORT_B_Parity=0;

	parameter PORT_A_DATA_WIDTH=1;
	parameter PORT_B_DATA_WIDTH=1;

	parameter PORT_B_WR_BE_WIDTH = 1;

	parameter [32767:0] INIT = {32768{1'b0}};
	parameter [2047:0] INIT_PARITY = {2048{1'b0}};
	
    localparam CLKPOL2 = 1;
	localparam CLKPOL3 = 1;
    localparam ABITS = 14;

    input PORT_A_CLK;
	input PORT_B_CLK;

	input [ABITS-1:0] PORT_A_ADDR;
	output [PORT_A_WIDTH-1:0] PORT_A_RD_DATA;
	input PORT_A_RD_EN;

	input [ABITS-1:0] PORT_B_ADDR;
	input [PORT_B_WIDTH-1:0] PORT_B_WR_DATA;
	input PORT_B_WR_EN;
	input [PORT_B_WR_BE_WIDTH-1:0] PORT_B_WR_BE;
	wire [PORT_A_WIDTH-1:0] A1DATA;
	wire [PORT_B_WIDTH-1:0] B1DATA;


	assign A1DATA = PORT_B_Parity ? ({PORT_A_RD_DATA[17],PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9],PORT_A_RD_DATA[7:0]}): PORT_A_RD_DATA[PORT_A_WIDTH-1:0];
	assign B1DATA = PORT_B_Parity ? ({PORT_B_WR_DATA[17],PORT_B_WR_DATA[8],PORT_B_WR_DATA[16:9],PORT_B_WR_DATA[7:0]}): PORT_B_WR_DATA[PORT_B_WIDTH-1:0];
	
	BRAM2x18_SDP #(
		.CFG_DBITS(),
		.PORT_A_WIDTH(PORT_A_WIDTH),
		.PORT_B_WIDTH(PORT_B_WIDTH),
		.PORT_A_DATA_WIDTH(PORT_A_DATA_WIDTH),
		.PORT_B_DATA_WIDTH(PORT_B_DATA_WIDTH),
		.CFG_ENABLE_B(PORT_B_WR_BE_WIDTH),
		.CLKPOL2(CLKPOL2),
		.CLKPOL3(CLKPOL3),
		.INIT0(INIT),
		.INIT0_PARITY(INIT_PARITY)
	) _TECHMAP_REPLACE_ (
		.A1ADDR(PORT_A_ADDR),
		.A1DATA(A1DATA),
		.A1EN(PORT_A_RD_EN),
		.CLK1(PORT_A_CLK),

		.B1ADDR(PORT_B_ADDR),
		.B1DATA(B1DATA),
		.B1EN(PORT_B_WR_EN),
		.B1BE(PORT_B_WR_BE),
		.CLK2(PORT_B_CLK)
	);
endmodule

module \$__RS_FACTOR_BRAM36_SDP (...);
	//parameter WIDTH = 1;
	parameter PORT_B_WIDTH=1;
	parameter PORT_A_WIDTH=1;


	parameter PORT_B_Parity =0;
	parameter PORT_A_DATA_WIDTH=1;
	parameter PORT_B_DATA_WIDTH=1;

	parameter PORT_B_WR_BE_WIDTH = 1;

	parameter [32767:0] INIT = {32768{1'b0}};
	parameter [4095:0] INIT_PARITY = {4096{1'b0}};
	
    localparam ABITS = 15;
	localparam CFG_ENABLE = 4;

	input PORT_A_CLK;
	input PORT_B_CLK;

	input [ABITS-1:0] PORT_A_ADDR;
	output [PORT_A_WIDTH-1:0] PORT_A_RD_DATA;
	input PORT_A_RD_EN;

	input [ABITS-1:0] PORT_B_ADDR;
	input [PORT_B_WIDTH-1:0] PORT_B_WR_DATA;
	input PORT_B_WR_EN;
	input [PORT_B_WR_BE_WIDTH-1:0] PORT_B_WR_BE;

	wire [35:0] DOBDO;
	wire [35:PORT_A_WIDTH] A1DATA_CMPL;
	wire [35:PORT_B_WIDTH] B1DATA_CMPL;
	wire [35:0] A1DATA_TOTAL;
	wire [35:0] B1DATA_TOTAL;

	wire FLUSH1;
	wire FLUSH2;

	wire [CFG_ENABLE-1:PORT_B_WR_BE_WIDTH] B1EN_CMPL = {CFG_ENABLE-PORT_B_WR_BE_WIDTH{1'b0}};
	wire [CFG_ENABLE-1:0] B1EN = {B1EN_CMPL, PORT_B_WR_BE};



	/*Adjusting the bit placement w.r.t new BRAM Primitve TDP_RAM36K*/
	// PORT A
case (PORT_A_WIDTH)
9: begin
	case (PORT_A_DATA_WIDTH)
	9: begin
		assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
	end
	18: begin
		assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
	end
	32,36: begin
		assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
	end
	default: begin
		assign PORT_A_RD_DATA = {A1DATA_TOTAL[32], A1DATA_TOTAL[7:0]};
	end
endcase
end
18: begin
	case (PORT_A_DATA_WIDTH)
		18: begin
			assign {A1DATA_TOTAL[33],A1DATA_TOTAL[32],A1DATA_TOTAL[15:0]} = {PORT_A_RD_DATA[17],PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		end
		32,36: begin
			assign {A1DATA_TOTAL[33],A1DATA_TOTAL[32],A1DATA_TOTAL[15:0]} = {PORT_A_RD_DATA[17],PORT_A_RD_DATA[8],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		end
		default: begin
			assign PORT_A_RD_DATA = {A1DATA_TOTAL[33],A1DATA_TOTAL[32],A1DATA_TOTAL[15:0]};
		end
	endcase
end
36: begin
	case(PORT_A_DATA_WIDTH)
		36:begin
			assign A1DATA_TOTAL = {PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		end
		27:begin
			assign A1DATA_TOTAL = {PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]};
		end
		default: begin
			assign A1DATA_TOTAL = (!PORT_B_Parity)? PORT_A_RD_DATA[PORT_A_WIDTH-1:0]:
								({PORT_A_RD_DATA[35],PORT_A_RD_DATA[26], PORT_A_RD_DATA[17], PORT_A_RD_DATA[8], PORT_A_RD_DATA[34:27], PORT_A_RD_DATA[25:18],PORT_A_RD_DATA[16:9], PORT_A_RD_DATA[7:0]});
		end
	endcase
end
default: begin
	assign PORT_A_RD_DATA = A1DATA_TOTAL[PORT_A_WIDTH-1:0];
	
end
endcase
// PORT B
case (PORT_B_WIDTH)
	9: begin
		
		case (PORT_B_DATA_WIDTH)
			9:begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			18:begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end 
			32,36: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			default: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], B1DATA_CMPL[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,B1DATA_CMPL[16:9], PORT_B_WR_DATA[7:0]};
			end
		endcase

	end
	18: begin
		
		case (PORT_B_DATA_WIDTH)
			18: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			32,36: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[26], PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],B1DATA_CMPL[34:27],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
			end
			default: begin
				assign B1DATA_TOTAL = {B1DATA_CMPL[35],B1DATA_CMPL[34], PORT_B_WR_DATA[17], PORT_B_WR_DATA[16],B1DATA_CMPL[33:26],B1DATA_CMPL[25:18] ,PORT_B_WR_DATA[15:8], PORT_B_WR_DATA[7:0]};
			end
		endcase
	end
	36: begin
		
		case(PORT_B_DATA_WIDTH)
		27:begin
			assign B1DATA_TOTAL = {PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		end
		36:begin
			assign B1DATA_TOTAL = {PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]};
		end
		default: begin
			assign B1DATA_TOTAL =(!PORT_B_Parity)? {B1DATA_CMPL, PORT_B_WR_DATA}:
								({PORT_B_WR_DATA[35], PORT_B_WR_DATA[26],PORT_B_WR_DATA[17], PORT_B_WR_DATA[8],PORT_B_WR_DATA[34:27],PORT_B_WR_DATA[25:18], PORT_B_WR_DATA[16:9], PORT_B_WR_DATA[7:0]});
		end
	endcase
	end
	default: begin
		assign B1DATA_TOTAL = {B1DATA_CMPL, PORT_B_WR_DATA};
		
	end
endcase
/*****************************************************************/
	TDP_RAM36K #(
		.INIT (INIT), // Initial Contents of memory
		.INIT_PARITY (INIT_PARITY), // Initial Contents of memory
		.WRITE_WIDTH_A (PORT_A_WIDTH), // Write data width on port A (1-36)
		.READ_WIDTH_A (PORT_A_WIDTH), // Read data width on port A (1-36)
		.WRITE_WIDTH_B (PORT_B_WIDTH), // Write data width on port B (1-36)
		.READ_WIDTH_B (PORT_B_WIDTH) // Read data width on port B (1-36)
	  ) _TECHMAP_REPLACE_ (
		.WEN_B(PORT_B_WR_EN), // Write-enable port A
		.REN_B(1'b0), // Read-enable port A
		.WEN_A(1'b0), // Write-enable port B
		.REN_A(PORT_A_RD_EN), // Read-enable port B
		.CLK_B(PORT_B_CLK), // Clock port A
		.CLK_A(PORT_A_CLK), // Clock port B
		.BE_B(B1EN), // Byte-write enable port A
		.BE_A(4'b0), // Byte-write enable port B
		.ADDR_B(PORT_B_ADDR), // Address port A, align MSBs and connect unused MSBs to logic 0
		.ADDR_A(PORT_A_ADDR), // Address port B, align MSBs and connect unused MSBs to logic 0
		.WDATA_B({B1DATA_TOTAL[31:0]}), // Write data port A
		.WPARITY_B({B1DATA_TOTAL[35], B1DATA_TOTAL[34], B1DATA_TOTAL[33], B1DATA_TOTAL[32]}), // Write parity data port A
		.RDATA_B ({DOBDO[31:0]}), // Read data port B
		.RPARITY_B ({DOBDO[35], DOBDO[34], DOBDO[33], DOBDO[32]}), // Read parity port B
		.WDATA_A({16'hFFFF,16'hFFFF}), // Write data port B
		.WPARITY_A({4'hF}), // Write parity port B
		.RDATA_A ({A1DATA_TOTAL[31:0]}), // Read data port A
		.RPARITY_A ({A1DATA_TOTAL[35], A1DATA_TOTAL[34], A1DATA_TOTAL[33], A1DATA_TOTAL[32]}) // Read parity port A
	  );

	
endmodule
