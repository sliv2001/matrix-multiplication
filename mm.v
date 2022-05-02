module frequencyDivider(clk, res);
	parameter count = 5208;
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

module uart_tx(
	input wire clk,
	input wire [7:0] data,
	input wire valid,
	output wire tx,
	output wire ready
);

reg [3:0] status=0;
reg [7:0] data_reg;
reg ready_reg=1;
reg tx_reg=1;

assign tx = tx_reg;
assign ready = ready_reg;

always @(posedge clk)
begin
	if (valid)
	begin
		if (status==0)
		begin
			data_reg=data;
			tx_reg=0;
			status=1;
			ready_reg=0;
		end
		else if (status<9)
		begin
			tx_reg=data_reg[0];
			data_reg=data_reg>>1;
			status=status+1;
		end else if (status==9)
		begin		
			status=10;
			tx_reg=1;
		end else
		begin
			ready_reg=1;
		end
	end else 
	begin
		status=0;
		ready_reg=1;
	end
end

endmodule

module uart_rx(
	input wire clk,
	input wire rx,
	input wire ready,
	output wire [7:0] data,
	output wire valid
);

reg [3:0] status=0;
reg [7:0] data_reg = 0;
reg valid_reg=0;

assign valid = valid_reg;
assign data = data_reg;

always @(posedge clk)
begin
	if (ready)
	begin
		if (status==0)
		begin
			if (rx==0)
			begin
				status=1;
				valid_reg=0;
			end
		end else if (status<9)
		begin
			data_reg=data_reg>>1;
			data_reg[7]=rx;
			status=status+1;
		end
		else
		begin
			valid_reg=1;
			status=0;
		end
	end
	else
	begin
		valid_reg=0;
	end
end

endmodule

module mm (
	input wire rst,
	input wire [4:1] btn,
	input wire clk,
	input wire UART_RX,
	output wire [4:1] led,
	output [5:0] o,
	output wire UART_TX
);

/*Frequency divider*/
wire fracClk;
frequencyDivider fd1(clk, fracClk);

/*UART*/	
reg [7:0] tx_reg;
reg [7:0] rx_reg;
wire [7:0] rx_wire;
reg valid=0, wait_reg=0;
uart_tx utx1(fracClk, tx_reg, valid, UART_TX, led[1]);
uart_rx urx1(fracClk, UART_RX, 1, rx_wire, led[2]);

/*matrices*/
reg [7:0] matrice1[15:0];
reg [7:0] matrice2[15:0];
reg [15:0] matrice3[15:0];
reg [5:0] status;
reg prevLed=1;

assign o=rx_wire[5:0];

always @(posedge fracClk) 
begin

	/*RESET*/
	if (!rst)
	begin
		for (status=0; status<16; status=status+1)
		begin
			matrice1[status]=0;
			matrice2[status]=0;
			matrice3[status]=0;
		end
		status=0;
	end
	
	else
	begin
		if (led[2] && !prevLed)
		begin
			if (status<16)
			begin
				matrice1[status]=rx_wire;
				status=status+1;
			end else if (status<32)
			begin
				matrice2[status-16]=rx_wire;
				status=status+1;
			end
		end
		if (status<48 && status>31)
		begin
			if (led[1])
			begin
				if (!valid)
				begin
					tx_reg=matrice1[status-32];
					status=status+1;
					valid=1;
				end else
				begin
					if (wait_reg)
						valid=0;
					wait_reg=~wait_reg;
				end
			end
		end
		prevLed=led[2];
	end
end
	
endmodule