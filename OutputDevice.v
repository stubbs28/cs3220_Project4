module OutputDevice(dev, abus, dbus, we, clk);
	parameter DEV_LEN = 10;
	parameter DBITS = 32;
	parameter DEV_ADDR = 32'hF0000000;
		
	input wire [DBITS - 1 : 0] abus;
	inout wire [DBITS - 1 : 0] dbus;
	input wire we, clk;
	inout reg [DBITS - 1: 0] dev;
	
	// device read/write selection
	wire selDATA = abus == DEV_ADDR;
	wire wrDATA = we && selDATA;
	wire rdDATA = !we && selDATA;
	
	assign dbus = (rdDATA) ? dev : {DBITS{1'bz}};
	
	always @(posedge clk) begin
		if (wrDATA)	dev[DEV_LEN - 1 : 0] <= dbus[DEV_LEN - 1 : 0];
	end
endmodule