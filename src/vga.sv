`default_nettype none

// vga display timing module. Generates row, col and blank signals based and
// outputs corresponding row based on CLOCK_50. `
module vga
    (input logic clock, reset,
     output logic HS, VS, blank,
     output logic [8:0] row,
     output logic [9:0] col);

    // HS_comp = 1 when clk_count = 1599 => reset counter to 0
    // clk_count = number of clock cycles
    // is_HS_PW = 1 when in HS Tpw period
    // is_HS_DISP = 1 when in HS Tdisp period
    // VS_comp = 1 when row_count = 520 => reset counter to 0
    // row_count = number of row cycles
    // is_VS_PW = 1 when in VS Tpw period
    // is_VS_DISP = 1 when in VS Tdisp period

    logic HS_comp, in_HS_PW, in_HS_DISP, VS_comp, in_VS_PW, in_VS_DISP;
    logic [11:0] clk_count;
    logic [9:0] row_count;  

    logic row_clr, col_clr, row_en, col_en, clk_clr, HS_comp_L, VS_comp_L;
    
    assign blank = ~(in_HS_DISP & in_VS_DISP);
    assign HS = ~in_HS_PW;
    assign VS = ~in_VS_PW;
    assign HS_comp = ~HS_comp_L;
    assign VS_comp = ~VS_comp_L;

    assign row = row_count[8:0] - 9'd31;

    vga_fsm             fsm(.clock(clock), .*);

    Counter      #(12) c0(.D('0), .Q(clk_count), .clock(clock), .en(1'd1), 
                           .clear(clk_clr), .load('0), .up(1'd1), .reset);

    MagComparator #(12) m0(.A(clk_count), .B(12'd799), .AltB(HS_comp_L), 
                           .AeqB(), .AgtB());
    MagComparator #(10) m1(.A(row_count), .B(10'd520), .AltB(VS_comp_L), 
                           .AeqB(), .AgtB());                 
    
    OffsetCheck   #(12) HSPW(.is_between(in_HS_PW), .low('0), 
                             .delta(12'd95), .val(clk_count));
    OffsetCheck   #(12) HSDISP(.is_between(in_HS_DISP), .low(12'd143), 
                               .delta(12'd639), .val(clk_count));
    OffsetCheck   #(10) VSPW(.is_between(in_VS_PW), .low('0), .delta(10'd1), 
                             .val(row_count));
    OffsetCheck   #(10) VSDISP(.is_between(in_VS_DISP), .low(10'd31), 
                               .delta(10'd479), .val(row_count));

    Counter #(10) col_cnt(.D('0), .Q(col), .clock(clock), .en(col_en), 
                           .clear(col_clr), .load('0), .up(1'd1), .reset);
    Counter #(10)  row_cnt(.D('0), .Q(row_count), .clock(clock), .en(row_en), 
                           .clear(row_clr), .load('0), .up(1'd1), .reset);

endmodule: vga

module vga_fsm (
  input logic VS_comp, HS_comp, in_HS_DISP, reset, clock,
  output logic row_clr, col_clr, row_en, col_en, clk_clr
);

  enum logic [2:0] {start, pre_HS_DISP, HS_DISP_en, 
                    post_HS_DISP} n_state, cur_state;

  always_comb begin
    row_clr = 0;
    col_clr = 0; 
    row_en = 0; 
    col_en = 0;
    clk_clr = 0;
    case (cur_state)
      start: begin
        clk_clr =  1;
        row_clr =  1;
      end
      pre_HS_DISP: begin
        col_clr = in_HS_DISP ? 1 : 0;
      end
      HS_DISP_en: col_en = 1;
      post_HS_DISP: begin
        if (HS_comp) begin
          clk_clr = 1;
          row_en = ~VS_comp;
          row_clr = VS_comp;
        end
      end
    endcase
  end

  always_comb begin
    case (cur_state)
      start: n_state = pre_HS_DISP;
      pre_HS_DISP: n_state = in_HS_DISP ? HS_DISP_en : pre_HS_DISP;
      HS_DISP_en: n_state = in_HS_DISP ? HS_DISP_en : post_HS_DISP;
      post_HS_DISP: n_state = HS_comp ? pre_HS_DISP : post_HS_DISP;
      default: n_state = start;
    endcase
  end

  always_ff @(posedge clock)
    if (reset)
      cur_state <= start;
    else
      cur_state <= n_state;

endmodule: vga_fsm

module Counter
  #(parameter WIDTH = 4)
   (input logic en, clear, load, up, clock, reset,
    input logic [WIDTH-1:0] D,
    output logic [WIDTH-1:0] Q);

    always_ff @(posedge clock, posedge reset)
      if (reset) 
        Q <= 0;
      else if (clear)
        Q <= 0;
      else if (load)
        Q <= D;
      else if (en)
        if (up)
          Q <= Q + 1;
        else
          Q <= Q - 1;

endmodule: Counter

module RangeCheck
    #(parameter WIDTH = 8)
    (output logic is_between,
     input logic  [WIDTH - 1:0] high, low, val);

     logic is_below_high, is_above_low, is_eq_low, is_eq_high;

     assign is_between = ((is_below_high | is_eq_high) & 
                          (is_above_low | is_eq_low));
     
     MagComparator #(WIDTH) m0(.A(val), .B(high), .AltB(is_below_high), 
                       .AeqB(is_eq_high), .AgtB());
     MagComparator #(WIDTH) m1(.A(val), .B(low), .AltB(), .AeqB(is_eq_low),
                       .AgtB(is_above_low));
     
endmodule: RangeCheck

// module that checks if a value is between low and low + delta inclusive
module OffsetCheck
    #(parameter WIDTH = 8)
    (output logic is_between,
     input logic [WIDTH - 1:0] low, delta, val);
     
    RangeCheck #(WIDTH) rc(is_between,low + delta, low, val);

endmodule: OffsetCheck

// Compares 2 WIDTH bit numbers A and B 
// and sets AeqB when equal,
// sets AltB if A < B and
// sets AgtB if A > B
module MagComparator
  #(parameter WIDTH = 8)
  (input logic [WIDTH-1:0] A, B, 
   output logic AltB, AeqB, AgtB);

   assign AeqB = A === B;
   assign AltB = A < B;
   assign AgtB = A > B;

endmodule: MagComparator