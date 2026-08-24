module top (
    input  wire       clk,       
    input  wire [1:0] mode,       // 00: Up, 01: Down, 10: Stopwatch
    input  wire       run,        // 1: Run, 0: Pause
    input  wire       reset,      // 1: Reset
    output reg  [2:0] comm,       // Common Cathodes for 3 Digits 
    output reg  [6:0] seg         // Segments A, B, C, D, E, F, G 
);


//Clock Divider

    reg [23:0] count_1  = 0;
    reg [20:0] count_10 = 0;
    reg        clk_1hz  = 0;
    reg        clk_10hz = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_1  <= 0;
            count_10 <= 0;
            clk_1hz  <= 0;
            clk_10hz <= 0;
        end else begin
           
            if (count_1 == 24'd11_999_999) begin
                count_1 <= 0;
                clk_1hz <= 1'b1;
            end else begin
                count_1 <= count_1 + 1'b1;
                clk_1hz <= 1'b0;
            end
 if (count_10 == 21'd1_199_999) begin
                count_10 <= 0;
                clk_10hz <= 1'b1;
            end else begin
                count_10 <= count_10 + 1'b1;
                clk_10hz <= 1'b0;
            end
        end
    end

    wire pulse = (mode == 2'b10) ? clk_10hz : clk_1hz;

//Counter

    reg [3:0] d0 = 4'd0; // Ones Digit
    reg [3:0] d1 = 4'd0; // Tens Digit
    reg [3:0] d2 = 4'd0; // Hundreds Digit

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            d0 <= 4'd0;
            d1 <= 4'd0;
            d2 <= 4'd0;
        end else if (run && pulse) begin
  case (mode)
  2'b00, 2'b10: begin // UP COUNTER & STOPWATCH
                    if (d0 == 4'd9) begin
                        d0 <= 4'd0;
                        if (d1 == 4'd9) begin
                     d1 <= 4'd0;
                            d2 <= (d2 == 4'd9) ? 4'd0 : d2 + 4'd1;
                        end else d1 <= d1 + 4'd1;
                    end else d0 <= d0 + 4'd1;
                end

                2'b01: begin // DOWN COUNTER
                    if (d0 == 4'd0) begin
                        d0 <= 4'd9;
                        if (d1 == 4'd0) begin
       d1 <= 4'd9;
                            d2 <= (d2 == 4'd0) ? 4'd9 : d2 - 4'd1;
                        end else d1 <= d1 - 4'd1;
                    end else d0 <= d0 - 4'd1;
                end
            endcase
        end
    end

//Display

    reg [15:0] mux_clk = 0;
    reg [1:0]  digit_select = 0;
    reg [3:0]  current_digit = 0;

    always @(posedge clk) begin
        mux_clk <= mux_clk + 1'b1;
        if (mux_clk == 0) begin
            digit_select <= (digit_select == 2'd2) ? 2'd0 : digit_select + 1'b1;
        end
    end

    always @(*) begin
        case (digit_select)
            2'd0: begin comm = 3'b110; current_digit = d0; end // Digit 0 (Right)
            2'd1: begin comm = 3'b101; current_digit = d1; end // Digit 1 (Middle)
            2'd2: begin comm = 3'b011; current_digit = d2; end // Digit 2 (Left)
            default: begin comm = 3'b111; current_digit = 4'd0; end
        endcase
    end

    always @(*) begin
        case (current_digit)
            4'h0: seg = 7'b1111110; // 0
            4'h1: seg = 7'b0110000; // 1
            4'h2: seg = 7'b1101101; // 2
            4'h3: seg = 7'b1111001; // 3
            4'h4: seg = 7'b0110011; // 4
            4'h5: seg = 7'b1011011; // 5
            4'h6: seg = 7'b1011111; // 6
            4'h7: seg = 7'b1110000; // 7
            4'h8: seg = 7'b1111111; // 8
            4'h9: seg = 7'b1110011; // 9
            default: seg = 7'b0000000;
        endcase
    end

endmodule
