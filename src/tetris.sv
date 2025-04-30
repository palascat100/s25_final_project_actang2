`default_nettype none

module tetris(
    input logic toggle_async, drop_async, save_async, rotate_async, 
    input logic MISO,
    input logic clock, reset,
    output logic play,
    output logic R1, R0, G1, G0, B1, B0, 
    output logic VS, HS,
    output logic MOSI, CS, SCK
);
    logic blank;
    logic [8:0] vga_row;
    logic [9:0] vga_col;
    vga timing(.clock(clock), .reset, .HS, .VS, .blank, 
               .row(vga_row), .col(vga_col));

    logic start, done, spi_done;
    logic [55:0] MISO_all;
    logic [7:0] x, y;
    spi spi_controller(.done(spi_done), .*);
    assign done = spi_done;
    
    logic val, piece_active;
    logic [2:0] piece_type, save_type;
    logic [4:0] grid_row;
    logic [5:0] grid_col;
    logic [1:0] red, green, blue;
    logic save_read;
    assign {R1, R0} = red;
    assign {G1, G0} = green;
    assign {B1, B0} = blue;
    logic grid_read, end_row, end_col;
    logic end_grid;
    logic [2:0] vga_piece;
    assign vga_piece = (save_read) ? save_type : piece_type;
    vga_translate translate(.piece_type(vga_piece), .*);
    
    
    logic rotate, left, right, down, save, drop;
    logic new_piece, mv_piece, update;
    logic pixel_num_clr, fsm_en;
    logic [1:0] pixel_num;
    logic [4:0] pixel_row;
    logic [5:0] pixel_col;
    // tells other modules if they should update
    logic [3:0] cnt;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) cnt <= '0;
        else cnt <= cnt + 4'd15;
    end

    logic should_update_once;
    assign update = should_update_once & ((vga_row == 9'd480) & (vga_col == 10'd640));
    always_ff @(posedge clock, posedge reset) begin
        if (reset) should_update_once <= '1;
        else if (vga_row == 9'd480) should_update_once <= '0;
        else if (vga_row == 9'd0) should_update_once <= '1;
    end

    // ==================== piece ====================
    logic [3:0] piece_col, nxt_piece_col;
    logic [4:0] piece_row, nxt_piece_row;
    logic [1:0] orientation, nxt_orientation;

    logic [1:0] save_num;

    // ==================== current piece ====================
    // piece_col_reg
    always_ff @(posedge clock, posedge reset) begin
        if (reset) piece_col <= '0;
        else if (new_piece) piece_col <= 4'd4;
        else if (mv_piece) piece_col <= nxt_piece_col;
    end

    // piece_row_reg
    always_ff @(posedge clock, posedge reset) begin
        if (reset) piece_row <= '0;
        else if (new_piece) piece_row <= 5'd0;
        else if (mv_piece) piece_row <= nxt_piece_row;
    end

    // piece_type_reg
    always_ff @(posedge clock, posedge reset) begin
        if (reset) piece_type <= 3'd1;
        else if (save & save_type != '0) piece_type <= save_type;
        else if (new_piece) piece_type <= (piece_type == 3'd7) ? 3'd1 : piece_type + 1;
    end

    // orientation_reg
    always_ff @(posedge clock, posedge reset) begin
        if (reset) orientation <= '0;
        else if (new_piece | mv_piece) orientation <= nxt_orientation;
    end

    // pixel_num_cntr
    logic [1:0] pixel_init;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) pixel_num <= '0;
        else if (vga_col == '0 & ~blank) pixel_num <= pixel_init;
        else if (end_col & ~save_read & piece_active & ~blank) pixel_num <= pixel_num + 1;
        else if (update | pixel_num_clr) pixel_num <= '0;
        else if (fsm_en) pixel_num <= pixel_num + 1;
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) pixel_init <= '0;
        else if (update) pixel_init <= '0;
        else if (vga_col == 10'd640 & pixel_num != '0 & end_row) pixel_init <= pixel_num; 
    end

    // next piece logic
    always_comb begin
        nxt_orientation = orientation;
        nxt_piece_row = piece_row;
        nxt_piece_col = piece_col;
        if (drop) begin
            nxt_piece_row = piece_row+1;
        end else if (rotate) begin
            nxt_orientation = orientation + 1;
        end else if (left) begin
            nxt_piece_col = piece_col-1;
        end else if (right) begin
            nxt_piece_col = piece_col+1;
        end else if (down) begin
            nxt_piece_row = piece_row+1;
        end
    end

    // ==================== save piece ====================
     // piece_type_reg
    always_ff @(posedge clock, posedge reset) begin
        if (reset) save_type <= '0;
        else if (save) save_type <= piece_type;
    end

    // save_num_cntr    
    logic [1:0] save_init;
    logic save_num_en;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) save_num <= '0;
        else if (vga_col == '0 & ~blank) save_num <= save_init;
        else if (update) save_num <= '0;
        else if (save_num_en) save_num <= save_num + 1;
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) save_init <= '0;
        else if (update) save_init <= '0;
        else if (vga_col == 10'd640 & save_num != '0 & end_row) save_init <= save_num; 
    end

    logic pixel_valid;
    assign save_read = ~blank & ~grid_read;
    assign save_num_en = end_col & save_read & piece_active;
    assign pixel_valid = grid_read || (save_read & save_type != '0);

    logic [5:0] col_piece;
    logic [4:0] row_piece; 
    logic [2:0] type_piece;
    logic [1:0] orientation_piece, num_pixel;

    assign col_piece = (save_read) ? 6'd15 : (nxt_piece_col < 4'd12) ? {2'd0 , nxt_piece_col} : {nxt_piece_col[3],nxt_piece_col[3] , nxt_piece_col};
    assign row_piece = (save_read) ? 5'd0 : {nxt_piece_row};
    assign type_piece = (save_read) ? save_type : piece_type;
    assign orientation_piece = (save_read) ? '0 : nxt_orientation;
    assign num_pixel = (save_read) ? save_num : pixel_num;
    // logic [4:0] grid_row;
    // logic [5:0] grid_col;
    assign piece_active = grid_row == pixel_row && grid_col == pixel_col && pixel_valid;
    // WIRE LENGTH MISMATCH CAUSING ISSUES
    // logic [1:0] pixel_num;
    // logic [4:0] pixel_row;
    // logic [5:0] pixel_col;
    always_comb begin 
        case (type_piece)
            3'd1: case (orientation_piece)
                2'd0: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + {4'b0, num_pixel}};
                2'd1: {pixel_row, pixel_col} = {row_piece + {3'b0, num_pixel}, col_piece + 6'd2};
                2'd2: {pixel_row, pixel_col} = {row_piece - 5'd1, col_piece + {4'b0, num_pixel}};
                2'd3: {pixel_row, pixel_col} = {row_piece + {3'b0, num_pixel}, col_piece + 6'd1};
            endcase
            3'd2: case (orientation_piece)
                2'd0: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                endcase
                2'd1: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece, col_piece+6'd2};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
                2'd2: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd2};
                endcase
                2'd3: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
            endcase
            3'd3: case (orientation_piece)
                2'd0: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd2};
                    2'd1: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                endcase
                2'd1: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd2};
                endcase
                2'd2: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece};
                endcase
                2'd3: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
            endcase
            3'd4: begin
                if (num_pixel > 2'd1) {pixel_row, pixel_col} = {row_piece + 5'd1 , col_piece + 6'd1 + {5'd0, num_pixel[0]}};
                else {pixel_row, pixel_col} = {row_piece , col_piece + 6'd1 + {5'd0, num_pixel[0]}};
            end
            3'd5: case (orientation_piece)
                2'd0: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece, col_piece+6'd2};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd1};
                endcase
                2'd1: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd2};
                endcase
                2'd2: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd2};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
                2'd3: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
            endcase
            3'd6: case (orientation_piece)
                2'd0: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                endcase
                2'd1: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
                2'd2: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
                2'd3: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
            endcase
            3'd7: case (orientation_piece)
                2'd0: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                endcase
                2'd1: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd2};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece + 6'd2};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd1};
                endcase
                2'd2: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece+6'd1};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece + 6'd2};
                endcase
                2'd3: case(num_pixel)
                    2'd0: {pixel_row, pixel_col} = {row_piece, col_piece+6'd1};
                    2'd1: {pixel_row, pixel_col} = {row_piece+5'd1, col_piece};
                    2'd2: {pixel_row, pixel_col} = {row_piece + 5'd1, col_piece+6'd1};
                    2'd3: {pixel_row, pixel_col} = {row_piece + 5'd2, col_piece};
                endcase
            endcase
            default: {pixel_row, pixel_col} = {row_piece, col_piece};
        endcase
    end
   
    logic re, we, shift, clear, valid, mem_sel;
    logic read;
    logic [4:0] mem_row;
    logic [3:0] mem_col;
    assign mem_row = (mem_sel) ? pixel_row : grid_row;
    assign mem_col = (mem_sel) ? pixel_col[3:0] : grid_col[3:0];
    assign re = grid_read | read;
    grid_mem mem(.row(mem_row), .col(mem_col), .w_val('1), .re, .we, .shift, 
                 .clock, .reset, .clear, .valid, .r_val(val));
    
    logic save_btn, rotate_btn, drop_btn, play_btn, play_btn_prev;
    synchronizer save_sync(.async(save_async), .clock, .sync(save_btn));
    synchronizer rotate_sync(.async(rotate_async), .clock, .sync(rotate_btn));
    synchronizer drop_sync(.async(drop_async), .clock, .sync(drop_btn));
    synchronizer play_sync(.async(toggle_async), .clock, .sync(play_btn));
    DFF play_prev(.D('1), .Q(play_btn_prev), .en(play_btn), .clr(~play_btn), .*);


     // ==================== game logic ====================
     // ==================== datapath ====================
    logic [4:0] vga_cnt;
    logic move;

    assign move = vga_cnt == 5'd8;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) vga_cnt <= '0;
        else if (move) vga_cnt <= 4'd0;
        else if (update) vga_cnt <= vga_cnt + 1;
    end

    logic [3:0] update_cnt;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) update_cnt <= '0;
        else if (update_cnt == 4'd5 & move) update_cnt <= 3'd0;
        else if (move) update_cnt <= update_cnt + 1;
    end

    // sample registers
    logic sample, all_clr, clr, swap, prev, prev_2;
    logic nat_down, manual_down, swap_valid, finish;
    assign prev = left | right | rotate;
    assign prev_2 = prev | manual_down;
    assign save = swap & swap_valid;
    assign down = manual_down | nat_down;
    assign finish = ~prev_2 & ~nat_down;
    DFF save_sample(.D(save_btn), .Q(swap), .en(sample), .clr(all_clr), .*);
    DFF drop_sample(.D(drop_btn), .Q(drop), .en(sample), .clr(all_clr), .*);
    DFF rotate_sample(.D(rotate_btn), .Q(rotate), .en(sample), .clr(clr | all_clr), .*);
    DFF left_sample(.D(y < 8'd110), .Q(left), .en(sample), .clr((clr & ~rotate) | all_clr), .*);
    DFF right_sample(.D(y > 8'd145), .Q(right), .en(sample), .clr((clr & ~rotate) | all_clr), .*);
    DFF down_sample(.D(x > 8'd145), .Q(manual_down), .en(sample), .clr((clr & ~prev) | all_clr), .*);
    DFF nat_down_sample(.D(update_cnt == 4'd5), .Q(nat_down), .en(sample), .clr((clr & ~prev_2) | all_clr), .*);
    DFF swap_valid_sample(.D('1), .Q(swap_valid), .en(new_piece & ~swap), .clr(swap), .*);
    DFF play_sample(.D(~play), .Q(play), .en(play_btn & ~play_btn_prev), .clr('0), .*);

    // ==================== fsm ====================
    enum logic [2:0] {IDLE, START, SPI, EFFECT, DROP, MOVE, LOAD, SHIFT} state;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= IDLE;
        else begin
            case(state) 
                IDLE: state <= START;
                START: state <= (move & play) ? SPI : START;
                SPI: state <= (done) ? EFFECT : SPI;
                EFFECT: begin
                    if (save) state <= START;
                    else if (drop) state <= DROP;
                    else state <= MOVE;
                end
                DROP: state <= (valid) ? DROP : LOAD;
                LOAD: state <= (pixel_num == 3) ? SHIFT : LOAD;
                SHIFT: state <= (clear) ? SHIFT : START;
                MOVE: begin
                    if (pixel_num == 3 & valid & finish) state <= START;
                    else if (~valid & ~prev & down) state <= LOAD;
                    else state <= MOVE;
                end
            endcase
        end
    end

    always_comb begin
        new_piece = 0;
        mv_piece = 0;
        start = 0;
        sample = 0;
        clr = 0;
        fsm_en = 0;
        all_clr = 0;
        pixel_num_clr = 0;
        we = 0;
        shift = 0;
        mem_sel = 1;
        read = 0;
        case (state)
            IDLE: begin 
                new_piece = 1;
                mem_sel = 0;
            end
            START: begin
                start = move & play;
                mem_sel = 0;
            end
            SPI: sample = done;
            EFFECT: new_piece = save;
            DROP: begin
                read = '1;
                fsm_en = valid;
                mv_piece = valid & pixel_num == 3;
                pixel_num_clr = ~valid;
                all_clr = ~valid;
            end
            LOAD: begin
                fsm_en = 1;
                we = 1;
            end
            SHIFT: begin
                shift = clear;
                new_piece = ~clear;
            end
            MOVE: begin
                read = '1;
                fsm_en = valid;
                mv_piece = pixel_num == 3 & valid;
                clr = (pixel_num == 3 & valid) | ~valid;
                pixel_num_clr = ~valid;
            end
        endcase
    end

endmodule: tetris

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

module DFF(
    input logic clock, reset,
    input logic en, clr,
    input logic D, 
    output logic Q
);
    always_ff @(posedge clock, posedge reset) begin
        if (reset) Q <= '0;
        else if (clr) Q <= '0;
        else if (en) Q <= D;
    end
endmodule: DFF