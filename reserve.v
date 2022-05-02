module frequencyDivider(clk, res);
	parameter count = 5208/8;
	input wire clk;
	output reg res;
	
	integer counter=0;
	
	always @(posedge clk)
	begin
		if (counter>=count/2)
		begin
			counter=0;
			res = ~res;
		end
		else
			counter=counter+1;
	end
	
endmodule

module mm (
	input wire rst,
	input wire [4:1] btn,
	input wire clk,
	output wire [4:1] led,
	output wire UART_TX
);
	parameter baud = 9600;

	wire redClk, unused1, unused2;
	reg [7:0] data = "h";

	frequencyDivider fd(clk, redClk);
	uart_tx uart1(redClk, ~rst, data, ~btn[1], unused1, UART_TX, unused2, 1);

endmodule