module sobel (
    input clk, rst,
    input [71:0] p_in,
    input p_valid,
    output reg [7:0] mag,
    output reg [7:0] dir,
    output reg c_valid
);
    wire signed [8:0] p0={1'b0,p_in[7:0]}, p1={1'b0,p_in[15:8]}, p2={1'b0,p_in[23:16]};
    wire signed [8:0] p3={1'b0,p_in[31:24]}, p5={1'b0,p_in[47:40]};
    wire signed [8:0] p6={1'b0,p_in[55:48]}, p7={1'b0,p_in[63:56]}, p8={1'b0,p_in[71:64]};

    // Stage 1: gx, gy
    reg signed [10:0] gx_r, gy_r;
    reg v1;
    always @(posedge clk) begin
        gx_r <= (p2 + (p5<<<1) + p8) - (p0 + (p3<<<1) + p6);
        gy_r <= (p0 + (p1<<<1) + p2) - (p6 + (p7<<<1) + p8);
        v1   <= p_valid;
    end

    // Stage 2: abs values + sign
    reg [10:0] abs_gx_r, abs_gy_r;
    reg gx_sign_r, gy_sign_r;
    reg v2;
    always @(posedge clk) begin
        abs_gx_r  <= gx_r[10] ? (-gx_r) : gx_r;
        abs_gy_r  <= gy_r[10] ? (-gy_r) : gy_r;
        gx_sign_r <= gx_r[10];
        gy_sign_r <= gy_r[10];
        v2 <= v1;
    end

    // Stage 3: bin thresholds + sum_mag
    reg [11:0] gx_lo_r, gx_hi_r; // Expanded to 12 bits
    reg [10:0] sum_mag_r, abs_gy_r2;
    reg gx_sign_r2, gy_sign_r2;
    reg v3;

    // Expanded to 25 bits
    wire [24:0] gx_lo_full = abs_gx_r * 12'd1697;
    wire [24:0] gx_hi_full = abs_gx_r * 14'd9890;

    always @(posedge clk) begin
        gx_lo_r    <= gx_lo_full[23:12];   
        gx_hi_r    <= gx_hi_full[23:12];
        sum_mag_r  <= abs_gx_r + abs_gy_r;
        abs_gy_r2  <= abs_gy_r;
        gx_sign_r2 <= gx_sign_r;
        gy_sign_r2 <= gy_sign_r;
        v3         <= v2;
    end

    // Stage 4: compare, saturate, output
    always @(posedge clk) begin
        if (rst) begin
            mag <= 0; dir <= 0; c_valid <= 0;
        end else begin
            mag <= (sum_mag_r > 11'd255) ? 8'hFF : sum_mag_r[7:0];
            if (abs_gy_r2 <= gx_lo_r)          dir <= 8'd0; // horizontal
            else if (abs_gy_r2 >= gx_hi_r)     dir <= 8'd2; // vertical
            else if (gx_sign_r2 == gy_sign_r2) dir <= 8'd1; // 45 deg
            else                               dir <= 8'd3; // 135 deg
            c_valid <= v3;
        end
    end
endmodule
