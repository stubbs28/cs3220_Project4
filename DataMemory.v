module DataMemory(clk, wrtEn, addr, dbus);
	parameter MEM_INIT_FILE;
	parameter ADDR_BIT_WIDTH = 32;
	parameter DATA_BIT_WIDTH = 32;
	parameter TRUE_ADDR_BIT_WIDTH = 11;
	parameter N_WORDS = (1 << TRUE_ADDR_BIT_WIDTH);

	input clk, wrtEn;
	input [ADDR_BIT_WIDTH - 1 : 0] addr;
	inout [DATA_BIT_WIDTH - 1 : 0] dbus;

	(* ram_init_file = MEM_INIT_FILE *)
	reg [DATA_BIT_WIDTH - 1 : 0] data [0 : N_WORDS - 1];
	reg [TRUE_ADDR_BIT_WIDTH - 1 :0] addr_reg;

	always @(negedge clk) begin
		if (wrtEn && !addr[29]) data[addr[13:2]] <= dbus;
		addr_reg <= addr[13:2];
	end
	
	assign dbus = (!wrtEn && !addr[29]) ? data[addr_reg] : {DATA_BIT_WIDTH{1'bz}};
endmodule
