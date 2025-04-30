`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    logic play;

    assign io_out[11] = play;
    logic R1, R0, G1, G0, B1, B0;

    assign {io_out[5], io_out[4]} = {B1, B0};
    assign {io_out[3], io_out[2]} = {G1, G0};
    assign {io_out[1], io_out[0]} = {R1, R0};

    tetris game(.toggle_async(io_in[0]), .drop_async(io_in[1]), .save_async(io_in[2]), .rotate_async(io_in[3]), 
                .MISO(io_in[4]), .clock, .reset,
                .R1, .R0, .G1, .G0, .B1, .B0, 
                .VS(io_out[7]), .HS(io_out[6]),
                .MOSI(io_out[8]), .CS(io_out[9]), .SCK(io_out[10]), .play);

endmodule
