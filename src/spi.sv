`default_nettype none
module spi(
    input  logic        start, clock, reset,
    input  logic        MISO,
    output logic        done,
    output logic        SCK, MOSI, CS,
    output logic [55:0] MISO_all,
    output logic [7:0]  x, y
);
    // ==================== datapath ====================
    // clock_cntr
    logic [4:0] clk_cnt;
    logic clk_clr, clk_cntr_clk;
    assign clk_clr = clk_cnt == 5'd13;
    assign clk_cntr_clk = clk_clr | start;
    Counter #(5) clock_cntr(.clear(clk_cntr_clk), .en('1), .Q(clk_cnt), 
                            .load('0), .D('0), .up('1), .*);

    // clock_level_reg
    logic level;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) level <= '0;
        else if (start) level <= '0;
        else if (clk_clr) level <= ~level;
    end

    // bit_cntr
    logic [2:0] bit_cnt;
    logic bit_clr, bit_en, sending;
    assign bit_en = sending & clk_clr & level;
    Counter #(3) bit_cntr(.clear(bit_clr), .en(bit_en), .Q(bit_cnt),
                          .load('0), .D('0), .up('1), .*);

    // byte_cntr
    logic [2:0] byte_cnt;
    logic byte_clr, byte_en;
    assign byte_en = bit_cnt == 7 & bit_en;
    Counter #(3) byte_cntr(.clear(byte_clr), .en(byte_en), .Q(byte_cnt), 
                           .load('0), .D('0), .up('1), .*);

    // microsec_cntr
    logic [3:0] microsec_cnt;
    logic micro_clr, micro_en;
    assign micro_en = clk_clr & level;
    Counter microsec_cntr(.clear(micro_clr), .en(micro_en), .Q(microsec_cnt),
                          .load('0), .D('0), .up('1), .*);
    
    // MOSI_PISO
    logic MOSI_ld, MOSI_en, bit_out;
    logic [7:0] MOSI_in, MOSI_reg;
    assign bit_out = MOSI_reg[7];
    assign MOSI_en = clk_clr & level & sending;
    assign MOSI_in = (byte_cnt > 0) ? 8'h0 : 8'hc0;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) MOSI_reg <= '0;
        else if (MOSI_ld) MOSI_reg <= MOSI_in;
        else if (MOSI_en) MOSI_reg <= MOSI_reg << 1;
    end

    // MISO_SIPO
    logic MISO_en;
    logic [15:0] MISO_out;
    assign MISO_en = clk_clr & ~level & sending;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) MISO_out <= '0;
        else if (MISO_en) MISO_out <= {MISO_out[14:0], MISO};
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) MISO_all <= '0;
        else if (MISO_en) MISO_all <= {MISO_all[54:0], MISO};
    end

    assign SCK = sending ? level : '0;
    assign MOSI = sending ? bit_out : '0;
    assign x = MISO_out[15:8];
    assign y = MISO_out[7:0];
    
    // ==================== fsm ====================
    enum logic [1:0] {IDLE, WAIT_15, SEND_BYTE, WAIT_10} state;

    // state logic
    always_ff @(posedge clock, posedge reset) begin
        if (reset) state <= IDLE;
        else begin
            case (state)
                IDLE: state <= (start) ? WAIT_15 : IDLE;
                WAIT_15: state <= (microsec_cnt == 4'd14 & micro_en) ? SEND_BYTE : WAIT_15;
                SEND_BYTE: state <= (bit_cnt == 7 & bit_en) ? WAIT_10 : SEND_BYTE;
                WAIT_10: begin
                    if (microsec_cnt == 4'd9 & micro_en & byte_cnt != 7) state <= SEND_BYTE;
                    else if (microsec_cnt == 4'd9 & micro_en & byte_cnt == 7) state <= IDLE;
                    else state <= WAIT_10;
                end
            endcase
        end
    end

    // control signal logic
    always_comb begin
        CS = 0;
        micro_clr = '0;
        MOSI_ld = '0;
        bit_clr = '0;
        byte_clr = '0;
        sending = '0;
        done = '0;

        case (state)
            IDLE: begin
                CS = ~start;
                micro_clr = start;
                bit_clr = start;
                byte_clr = start;
            end
            WAIT_15: begin
                MOSI_ld = microsec_cnt == 4'd14 & micro_en;
            end
            SEND_BYTE: begin
                sending = '1;
                micro_clr = bit_cnt == 7 & bit_en;
            end
            WAIT_10: begin
                MOSI_ld = microsec_cnt == 4'd9 & micro_en & byte_cnt != 7;
                bit_clr = microsec_cnt == 4'd9 & micro_en & byte_cnt != 7;
                done = microsec_cnt == 4'd9 & micro_en & byte_cnt == 7;
            end
        endcase
    end

endmodule: spi