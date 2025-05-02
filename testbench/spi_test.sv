module spi_test();
  logic        start, clock, rst_n;
  logic        MISO;
  logic done;
  logic SCK, MOSI, CS;
  logic [7:0]  x, y;

  logic [63:0] array;
  assign array = {8'hA1, 8'h2A, 8'hA3, 8'h4A, 8'hA5, 8'h6A, 8'hA7, 8'h8A};  
  logic [5:0] index;
  spi dut(.*);

  always_ff @(negedge SCK, posedge reset) begin
    if (reset) index <= 6'd63;
    else if (~CS) index <= index - 1;
  end

  assign MISO = array[index];
  
  initial begin
    rst_n = 1'b0;
    rst_n <= 1'b1;
    clock = 1'b0;
    forever #10 clock = ~clock;
  end
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    start <= '0;

    for (int i = 0; i < 10; i ++) begin
        @(posedge clock);
    end

    start <= '1;
    @(posedge clock);
    start <= '0;

    while (~done) begin
        @(posedge clock);
    end
    $dumpoff;
    $finish;
  end
endmodule: spi_test