`default_nettype none
module ChipInterface(
    input logic clk,
    input logic gp15, 
    input logic [3:0] sw,
    input logic [6:0] btn,
    output logic [7:0] led,
    output logic gp14, gp16, gp17, 
    output logic gp21, gp22, gp23, gp24,
    output logic gn21, gn22, gn23, gn24
);  
    logic clock;
    assign clock = clk;

    logic blank, reset;
    logic [8:0] row;
    logic [9:0] col;
    logic [7:0] VGA_R, VGA_G, VGA_B;

    synchronizer sync_reset(.clock, .async(btn[5]), .sync(reset));

    vga vga_mod(.clock(clock), .reset(reset), .HS(gp21), .VS(gn21), 
                .blank, .row, .col);

    PatternGenerator pattern(.row, .col, .VGA_R, .VGA_G, .VGA_B);

    assign {gp22, gn22} = VGA_B[1:0];
    assign {gp23, gn23} = VGA_G[1:0];
    assign {gp24, gn24} = VGA_R[1:0];
       

endmodule: ChipInterface


// Generates pattern for VGA by assigning VGA_R, VGA_G and VGA_B based on row
// and col indices given by vga module. Creates an image that is black in the
// bottom half and black, blue, cyan, green, red, magenta, white then yellow in
// eight evenly spaced cols in the top half. 
module PatternGenerator
    (input logic [8:0] row,
     input logic [9:0] col,
     output logic [7:0] VGA_R, VGA_G, VGA_B);

    logic row_between, 
          col_between_320_639, col_between_160_319, col_between_480_639, 
          col_between_80_239, col_between_400_559;

    // Use RangeCheck to determine which half/eighth of the display we are in
    RangeCheck #(9) row_0_239(.is_between(row_between), .low(9'd0), 
                              .high(9'd239), .val(row));

    RangeCheck #(10) col_320_639(.is_between(col_between_320_639), 
                                 .low(10'd320), .high(10'd639), .val(col));
    RangeCheck #(10) col_160_319(.is_between(col_between_160_319), 
                                 .low(10'd160), .high(10'd319), .val(col));
    RangeCheck #(10) col_480_639(.is_between(col_between_480_639), 
                                 .low(10'd480), .high(10'd639), .val(col));
    RangeCheck #(10) col_80_239(.is_between(col_between_80_239), .low(10'd80), 
                                .high(10'd239), .val(col));
    RangeCheck #(10) col_400_559(.is_between(col_between_400_559), 
                                 .low(10'd400), .high(10'd559), .val(col));

    always_comb begin // logic for determining where on the display we are
        VGA_R = '0; 
        VGA_G = '0; 
        VGA_B = '0;
        if (row_between) begin
            if (col_between_320_639)
                VGA_R = 8'hFF;
            if (col_between_160_319 || col_between_480_639)
                VGA_G = 8'hFF;
            if (col_between_80_239 || col_between_400_559)
                VGA_B = 8'hFF;
        end
    end

endmodule: PatternGenerator

module synchronizer(
    input logic async, clock,
    output logic sync
);
    logic temp;
    always_ff @(posedge clock) begin
        temp <= async;
        sync <= temp;
    end
    
endmodule: synchronizer