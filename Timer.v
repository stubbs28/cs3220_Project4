module Timer(abus, dbus, we, intr, clk, init);
	parameter DBITS = 32;
	parameter TICKS_PER_MS = 10000; // 10,000,000 ticks * sec^-1 / 1,000 sec * ms^-1
	parameter CNT_ADDR = 32'hF0000020;
	parameter LIM_ADDR = 32'hF0000024;
	parameter CTL_ADDR = 32'hF0000120;
	parameter READY_BIT = 0;
	parameter OVERRUN_BIT = 2;
	parameter INTR_EN_BIT = 8;
	
	input wire [bits - 1 : 0] abus;
	inout wire [bits - 1 : 0] dbus;
	input wire we, clk, init;
	output wire intr;
	
	reg [DBITS - 1: 0] CNT, LIM, CTL, baseCounter;
	
	// device read/write selection
	wire selCNT = abus == CNT_ADDR;
	wire wrCNT = we && selCNT;
	wire rdCNT = !we && selCNT;
	
	wire selLIM = abus == LIM_ADDR;
	wire wrLIM = we && selLIM;
	wire rdLIM = !we && selLIM;
	
	wire selCTL = abus == CTL_ADDR;
	wire wrCTL = we && selCTL;
	wire rdCTL = !we && selCTL;
	
	// read from device
	assign dbus = rdCNT ? CNT :
					rdLIM ? LIM :
					rdCTL ? CTL :
					{DBITS{1'bz}};
					
	// update interupt
	assign intr = CTL[READY_BIT] && CTL[INTR_EN_BIT];
					
	always @(posedge clk) begin
		// init device
		if (init) begin
			CNT <= 32'd0;
			LIM <= 32'd0;
			CTL <= 32'd0;
			baseCounter <= 0;
		end
	
		// write to device
		if (wrCNT) CNT <= dbus;
		if (wrLIM) LIM <= dbus;
		if (wrCTL) begin
			if(dbus[READY_BIT] == 0) CTL[READY_BIT] <= 1'b0;
			if(dbus[OVERRUN_BIT] == 0) CTL[OVERRUN_BIT] <= 1'b0;
			CTL[INTR_EN_BIT] <= dbus[INTR_EN_BIT];
		end
		
		// count towards 1 ms here
		baseCounter <= baseCounter + 1;
		if (baseCounter == TICKS_PER_MS - 1) begin
			baseCounter <= 32'd0;
			counter <= counter + 1;
			if (LIM != 0 && CNT == LIM - 1) begin
				CNT <= 32'd0;
				CTL[OVERRUN_BIT] <= CTL[READY_BIT] | CTL[OVERRUN_BIT];
				CTL[READY_BIT] <= 1'b1;
			end
		end
	end	
endmodule