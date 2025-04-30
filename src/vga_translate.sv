`default_nettype none
`define TOP_ROW 20
`define LEFT_COL 20
`define N 4

module vga_translate(
    input logic [8:0] vga_row,
    input logic [9:0] vga_col,
    input logic val, piece_active,
    input logic [2:0] piece_type,
    output logic [4:0] grid_row,
    output logic [5:0] grid_col,
    output logic [1:0] red, green, blue,
    output logic grid_read, end_grid, end_row, end_col
);
    logic [8:0] shifted_row;
    logic [9:0] shifted_col;
    logic [`N-1:0] offset_row, offset_col;
    logic outline;

    enum logic [5:0] {WHITE=6'b11_11_11, 
                      BLACK=6'b00_00_00,
                      GRAY=6'b10_10_10, 
                      CYAN=6'b00_10_11,
                      BLUE=6'b00_00_11,
                      ORANGE=6'b11_10_00,
                      YELLOW=6'b11_11_00,
                      GREEN=6'b00_11_00,
                      PURPLE=6'b11_00_11,
                      RED=6'b11_00_00} color, piece_color, mem_color;

    assign shifted_row = vga_row - `TOP_ROW;
    assign shifted_col = vga_col - `LEFT_COL;
    
    assign grid_row = shifted_row[8:`N];
    assign grid_col = shifted_col[9:`N];
    
    assign offset_row = shifted_row[`N-1:0];
    assign offset_col = shifted_col[`N-1:0];

    assign grid_read = grid_row < 5'd20 & grid_col < 6'd12;
    assign {red, green, blue} = color;

    assign end_grid = offset_row == 4'd15 & offset_col == 4'd15;
    assign end_row = offset_row == 4'd15;
    assign end_col = offset_col == 4'd15;
    assign outline = (offset_row < 1 | offset_row > 14 | 
                      offset_col < 1 | offset_col > 14);
    
    assign mem_color = (val) ? GRAY : BLACK;
    
    always_comb begin
        case(piece_type)
            3'd1: piece_color = CYAN;
            3'd2: piece_color = BLUE;
            3'd3: piece_color = ORANGE;
            3'd4: piece_color = YELLOW;
            3'd5: piece_color = GREEN;
            3'd6: piece_color = PURPLE;
            3'd7: piece_color = RED;
            default: piece_color = BLACK;
        endcase
    end

    always_comb begin
        if (piece_active) begin
            if (outline) color = WHITE;
            else color = piece_color;
        end else begin
            if (grid_read) begin
                if (outline) color = WHITE;
                else color = mem_color;
            end else begin
                color = BLACK;
            end
        end
    end
    
endmodule: vga_translate