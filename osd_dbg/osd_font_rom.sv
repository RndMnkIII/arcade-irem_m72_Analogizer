`default_nettype none
module osd_font_rom (
    input  logic        clk,
    input  logic [10:0] addr,   // 128 chars * 8 lines = 1024 = 11 bits
    output logic [7:0]  data
);
    logic [7:0] rom [0:1023];

    initial begin
        $readmemh("ascii8x8_font.mem", rom);
    end

    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
endmodule
