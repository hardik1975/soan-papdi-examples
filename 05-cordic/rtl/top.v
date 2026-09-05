module top (
    input  wire rst,           
    input  wire i_ss_n,        // SPI Chip Select
    input  wire i_sck,         // SPI Clock
    input  wire i_mosi,        // SPI MOSI
    output wire o_miso,        // SPI MISO
    output wire o_cordic_done  
);

wire clk;


    SB_HFOSC inout_hfosc (
        .CLKHFPU(1'b1), // Power up oscillator
        .CLKHFEN(1'b1), // Enable clock output
        .CLKHF(clk)     // System clock output
    );

    defparam inout_hfosc.CLKHF_DIV = "0b01";


    wire        w_rx_valid;
    wire [15:0] w_rx_data;
    wire [15:0] w_cordic_cos;
    wire [15:0] w_cordic_sin;

    //1st half (Angle/Cos) 2nd half (Dummy/Sin) of 32-bit
    reg r_word_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_word_cnt <= 1'b0;
        end else if (i_ss_n) begin
            r_word_cnt <= 1'b0;
        end else if (w_rx_valid) begin
            r_word_cnt <= ~r_word_cnt;
        end
    end


    wire        w_cordic_start = w_rx_valid && (r_word_cnt == 1'b0);
    wire [15:0] w_tx_data      = (r_word_cnt == 1'b0) ? w_cordic_cos : w_cordic_sin;


    spi_target #(
        .CPOL(1'b0), .CPHA(1'b0), .WIDTH(16), .LSB(1'b0)
    ) u_spi_target (
        .i_clk           (clk),
        .i_rst_n         (~rst),
        .i_enable        (1'b1),
        .i_ss_n          (i_ss_n),
        .i_sck           (i_sck),
        .i_mosi          (i_mosi),
        .o_miso          (o_miso),
        .o_rx_data       (w_rx_data),
        .o_rx_data_valid (w_rx_valid),
        .i_tx_data       (w_tx_data),
        .o_tx_data_hold  ()
    );


    cordic_circular u_cordic (
        .clk             (clk),
        .rst             (rst),
        .start           (w_cordic_start),
        .angle_in        (w_rx_data),
        .cos_out         (w_cordic_cos),
        .sin_out         (w_cordic_sin),
        .done            (o_cordic_done) 
    );

endmodule
