module top (
    input clk,
    input rst_n,
    input [2:0] switches,
    output din,
    output sclk,
    output cs
);

    wire rst = ~rst_n;

    reg [7:0] row0, row1, row2, row3, row4, row5, row6, row7;

    wire [3:0] value = switches;
    integer col;

    always @(posedge clk) begin
        if (rst) begin
            row0 <= 0; row1 <= 0; row2 <= 0; row3 <= 0;
            row4 <= 0; row5 <= 0; row6 <= 0; row7 <= 0;
        end else begin
            for (col = 0; col < 8; col = col + 1) begin
                row0[col] <= (col < value);
                row1[col] <= (col < value);
                row2[col] <= (col < value);
                row3[col] <= (col < value);
                row4[col] <= (col < value);
                row5[col] <= (col < value);
                row6[col] <= (col < value);
                row7[col] <= (col < value);
            end
        end
    end

 
/*   // manual pattern block
     always @(posedge clk) begin
         row0 <= 8'b10000000;
         row1 <= 8'b11000000;
         row2 <= 8'b11100000;
         row3 <= 8'b11110000;
         row4 <= 8'b11111000;
         row5 <= 8'b11111100;
         row6 <= 8'b11111110;
         row7 <= 8'b11111111;
     end
*/


/*    // animation 
reg [23:0] frame_count;
reg [5:0] position;

always @(posedge clk) begin
    frame_count <= frame_count + 1;
    if (frame_count == 0) begin
        if (position == 63)
            position <= 0;
        else
            position <= position + 1;
    end
end

wire [2:0] active_row = position[5:3];
wire [2:0] active_col = position[2:0];

always @(posedge clk) begin
    row0 <= (active_row == 0) ? (8'b1 << active_col) : 8'b0;
    row1 <= (active_row == 1) ? (8'b1 << active_col) : 8'b0;
    row2 <= (active_row == 2) ? (8'b1 << active_col) : 8'b0;
    row3 <= (active_row == 3) ? (8'b1 << active_col) : 8'b0;
    row4 <= (active_row == 4) ? (8'b1 << active_col) : 8'b0;
    row5 <= (active_row == 5) ? (8'b1 << active_col) : 8'b0;
    row6 <= (active_row == 6) ? (8'b1 << active_col) : 8'b0;
    row7 <= (active_row == 7) ? (8'b1 << active_col) : 8'b0;
end
*/

    max display (
        .clk(clk),
        .rst(rst),
        .row0(row0), .row1(row1), .row2(row2), .row3(row3),
        .row4(row4), .row5(row5), .row6(row6), .row7(row7),
        .din(din),
        .sclk(sclk),
        .cs(cs)
    );

endmodule
