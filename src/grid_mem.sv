`default_nettype none
`define ROWS 20
`define COLS 12

module grid_mem #(parameter size = 1) (
    input  logic [$clog2(`ROWS)-1:0] row,
    input  logic [$clog2(`COLS)-1:0] col,
    input  logic [size-1:0]          w_val,
    input  logic                     re, we, shift, clock, reset, 
    output logic                     clear, valid,
    output logic [size-1:0]          r_val
);

    logic [$clog2(`ROWS)-1:0] decoder_row;
    logic [$clog2(`COLS)-1:0] decoder_col;
    logic [`ROWS-1:0] row_sel;
    logic [`COLS-1:0] col_sel;
    logic [`ROWS-1:0][`COLS-1:0][size-1:0] mem_matrix;
    logic [`ROWS-1:0] clr_rows;
    // logic [`COLS-1:0] clear_array;
    tri val;

    assign decoder_row = (row < 5'd20) ? row : '0;
    assign decoder_col = (col < 4'd12) ? col : '0;
    assign r_val = (re) ? val : '0;
    assign valid = (row < 5'd20) & (col < 4'd12) & ~r_val;
    assign clear = clr_rows[0];

    decoder #(`ROWS) row_decode(.binary(row), .one_hot(row_sel));
    decoder #(`COLS) col_decode(.binary(col), .one_hot(col_sel));

    genvar i;
    genvar j;
    generate
      for (i = 0; i < `ROWS; i = i + 1) begin: mem_rows
        
        if (i != `ROWS-1) begin
            assign clr_rows[i] = clr_rows[i+1] | &mem_matrix[i];
        end else begin
            assign clr_rows[i] = &mem_matrix[i];
        end

        for (j = 0; j < `COLS; j = j + 1) begin: mem_cols
            if (i != 0) begin
                always_ff @(posedge clock, posedge reset) begin
                    if (reset) begin
                        mem_matrix[i][j] <= '0;
                    end else if (shift & clr_rows[i]) begin
                        mem_matrix[i][j] <= mem_matrix[i-1][j];
                    end else if (row_sel[i] && col_sel[j] && we) begin
                        mem_matrix[i][j] <= w_val;
                    end
                end
            end else begin
                always_ff @(posedge clock, posedge reset) begin
                    if (reset) begin
                        mem_matrix[i][j] <= '0;
                    end else if (shift & clr_rows[i]) begin
                        mem_matrix[i][j] <= '0;
                    end else if (row_sel[i] && col_sel[j] && we) begin
                        mem_matrix[i][j] <= w_val;
                    end
                end
            end

            assign val = (row_sel[i] && col_sel[j] && re) ? mem_matrix[i][j] : 'z;
        end
      end
    endgenerate
endmodule: grid_mem

module decoder 
    #(parameter sel_lines = 8) (
        input logic [$clog2(sel_lines)-1:0] binary, 
        output logic [sel_lines-1:0] one_hot    
);
    genvar i;
    generate
      for (i = 0; i < sel_lines; i = i + 1) begin: decode_unit
        assign one_hot[i] = binary == i;
      end: decode_unit
    endgenerate
endmodule: decoder

// module grid_mem_test();
//   logic [4:0] row;
//   logic [3:0] col;
//   logic w_val, r_val;
//   logic re, we, shift, clear, valid;
//   logic rst_n, clock;
  
//   grid_mem #(1) mem(.*);
  
//   initial begin
//     rst_n = 1'b0;
//     rst_n <= 1'b1;
//     clock = 1'b0;
//     forever #5 clock = ~clock;
//   end
  
//   initial begin
//     $monitor($time,, "re = %b, r_val = %b clear = %b valid = %b", re, r_val, clear, valid);
//   end
  
//   initial begin
//     $dumpfile("dump.vcd"); $dumpvars;
//     row <= 5'd0;
//     col <= 4'd0;
//     w_val <= 1'd1;
//     re <= 1'd0;
//     we <= 1'd0;
//     shift <= 1'd0;
    
//     @(posedge clock);
//     row <= 5'd19;
//     @(posedge clock);
//     @(posedge clock);
//     we <= '1;
//     for (int i = 0; i < 12; i ++) begin
//       col <= i;
//       @(posedge clock);
//     end
//     we <= '0;
//     @(posedge clock);
//     re <= '1;
//     for (int i = 0; i < 12; i ++) begin
//       col <= i;
//       @(posedge clock);
//     end
//     re <= '0;
//     @(posedge clock);
//     @(posedge clock);
//     @(posedge clock);
//     shift <= '1;
//     @(posedge clock);
//     shift <= '0;
//     @(posedge clock);
//     @(posedge clock);
//     @(posedge clock);
//     $dumpoff;
//     $finish;
//   end
// endmodule: grid_mem_test