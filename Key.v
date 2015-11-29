module Key(keys, abus, dbus, we, intr, clk, init);
	parameter DBITS = 32;
	parameter DATA_ADDR = 32'hF0000010;
	parameter CTRL_ADDR = 32'hF0000110;
	parameter READY_BIT = 0;
	parameter OVERRUN_BIT = 2;
	parameter IE_BIT = 8;
	
	input wire [3 : 0] keys;
	input wire [bits - 1 : 0] abus;
	inout wire [bits - 1 : 0] dbus;
	input wire we, clk, init;
	output wire intr;
	
	reg [DBITS - 1: 0] CTRL, DATA;
	
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
		end
	
		// Set data from keys
		DATA[3:0] <= keys;
		if (DATA[3:0] != keys) begin
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