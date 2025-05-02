`default_nettype none
module ChipInterface(
    input logic clk,
    input logic gp15, 
    input logic [3:0] sw,
    input logic [6:0] btn,
    output logic [7:0] led,
    output logic gp14, gp16, gp17, 
);  
    logic clock;
    assign clock = clk;
    logic start_sync, select_sync, reset;
    assign reset = btn[3];
    synchronizer sync_start(.async(btn[5]), .clock, .sync(start_sync));
    synchronizer sync_select(.async(btn[4]), .clock, .sync(select_sync));

    logic [7:0]  x, y;
    logic [7:0] mem_x, mem_y;
    logic [55:0] MISO_all;
    logic done;
    spi dut(.start(start_sync), .clock, .reset(reset), 
            .MISO(gp15), .done, .SCK(gp14), .MOSI(gp16), .CS(gp17),
            .x, .y, .MISO_all);

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            mem_x <= '0;
        end else if (done) begin
            mem_x <= x;
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            mem_y <= '0;
        end else if (done) begin
            mem_y <= y;
        end
    end

    logic sync_old;
    always_ff @(posedge clock) begin
        sync_old <= select_sync;
    end

    logic [2:0] value_cnt;
    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            value_cnt <= '0;
        end else if (select_sync & ~sync_old) begin
            value_cnt <= value_cnt + 1;
        end
    end

    always_comb begin
        case(sw)
        4'd0: led = MISO_all[55:48];
        4'd1: led = MISO_all[47:40];
        4'd2: led = MISO_all[39:32];
        4'd3: led = MISO_all[31:24];
        4'd4: led = MISO_all[23:16];
        4'd5: led = MISO_all[15:8];
        4'd6: led = MISO_all[7:0];
        default: led = '0;
        endcase
    end

endmodule: ChipInterface

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