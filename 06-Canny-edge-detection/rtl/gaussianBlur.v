module gaussianBlur (
    input clk,
    input rst,
    input [71:0] p_in,
    input p_valid,
    output reg [7:0] c_out,
    output reg c_valid
);

    wire [7:0] p0 = p_in[7:0],   p1 = p_in[15:8],  p2 = p_in[23:16];
    wire [7:0] p3 = p_in[31:24], p4 = p_in[39:32], p5 = p_in[47:40];
    wire [7:0] p6 = p_in[55:48], p7 = p_in[63:56], p8 = p_in[71:64];

    // Stage 1: partial sums 
    reg [11:0] s01, s23, s45, s678;
    reg        v1;

    always @(posedge clk) begin
        if (rst) begin
            s01   <= 12'd0;
            s23   <= 12'd0;
            s45   <= 12'd0;
            s678  <= 12'd0;
            v1    <= 1'b0;
        end else begin
            s01   <= p0 + (p1 << 1);
            s23   <= p2 + (p3 << 1);
            s45   <= (p4 << 2) + (p5 << 1);
            s678  <= p6 + (p7 << 1) + p8;
            v1    <= p_valid;
        end
    end

    // Stage 2: final reduction + normalize (divide by 16)
    always @(posedge clk) begin
        if (rst) begin
            c_out   <= 8'd0;
            c_valid <= 1'b0;
        end else begin
            c_out   <= (s01 + s23 + s45 + s678) >> 4;
            c_valid <= v1;
        end
    end

endmodule
