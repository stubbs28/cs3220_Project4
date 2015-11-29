module Switch(sw, abus, dbus, we, intr, clk, init);
	parameter DBITS = 32;
	parameter MAX_TICKS = 100000; // 10,000,000 ticks * sec^-1 / 1,000 sec * ms^-1 * 10
	parameter DATA_ADDR = 32'hF0000014;
	parameter CTRL_ADDR = 32'hF0000114;
	parameter READY_BIT = 0;
	parameter OVERRUN_BIT = 2;
	parameter IE_BIT = 8;
	
	input wire [9 : 0] sw;
	input wire [DBITS - 1 : 0] abus;
	inout wire [DBITS - 1 : 0] dbus;
	input wire we, clk, init;
	output wire intr;
	
	reg [DBITS - 1: 0] CTRL, DATA, PREV_DATA, COUNTER;
	
	// device read/write selection
	wire selDATA = abus == DATA_ADDR;
	wire rdDATA = !we && selDATA;
	
	wire selCTRL = abus == CTRL_ADDR;
	wire wrCTRL = we && selCTRL;
	wire rdCTRL = !we && selCTRL;
	
	// read from device
	assign dbus = rdDATA ? DATA :
					rdCTRL ? CTRL :
					{DBITS{1'bz}};
					
	// update interupt
	assign intr = CTRL[READY_BIT] && CTRL[IE_BIT];
	
	always @(posedge clk) begin
		// init device
		if (init) begin 
			CTRL <= 32'd0;
			DATA <= 32'd0;
			PREV_DATA <= 32'd0;
		end
		
		COUNTER <= COUNTER + 1;
		if ((PREV_DATA[9:0] != sw) && (COUNTER < MAX_TICKS - 1)) begin
			PREV_DATA[9:0] <= sw;
			COUNTER <= 32'd0;
		end
		
		if(COUNTER == MAX_TICKS - 1) begin
			COUNTER <= 32'd0;
			DATA <= PREV_DATA;
			CTRL[OVERRUN_BIT] <= CTRL[READY_BIT] | CTRL[OVERRUN_BIT];
			CTRL[READY_BIT] <= 1'b1;
		end
				
		// clear ready bit
		if (rdDATA) CTRL[READY_BIT] <= 1'b0;
			
		// write to control reg
		if (wrCTRL) begin
			if(dbus[OVERRUN_BIT] == 0) CTRL[OVERRUN_BIT] <= 1'b0;
			CTRL[IE_BIT] <= dbus[IE_BIT];
		end
	end
endmodule