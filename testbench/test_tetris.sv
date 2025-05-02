module tetris_test();
    logic toggle_async, drop_async, save_async, rotate_async;
    logic MISO;
    logic clock, reset, play;
    logic R1, R0, G1, G0, B1, B0;
    logic VS, HS;
    logic MOSI, CS, SCK;

    assign toggle_async = '0;
    assign save_async = '0;
    assign rotate_async = '0;
    assign MISO = '0;

    tetris dut(.toggle_async, .drop_async, .save_async, .rotate_async, .MISO,
               .clock, .reset, .play, .R1, .R0, .G1, .G0, .B1, .B0, 
               .VS, .HS, .MOSI, .CS, .SCK);

    initial begin
        reset = 1'b1;
        reset <= 1'b0;
        clock = 1'b0;
        drop_async <= '0;
        forever #5 clock = ~clock;
    end

    initial begin
        for (int i = 0; i < 5000000; i++) begin
            @(posedge clock);
        end
        $finish;
    end

endmodule: tetris_test