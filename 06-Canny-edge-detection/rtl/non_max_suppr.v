module non_max_suppr (
    input clk,
    input [71:0] mag_data,
    input mag_valid,
    input [71:0] dir_data,
    input dir_valid,
    output reg [7:0] p_out,
    output reg p_vld
);

    wire [7:0] m0 = mag_data[7:0],   m1 = mag_data[15:8],  m2 = mag_data[23:16];
    wire [7:0] m3 = mag_data[31:24], m4 = mag_data[39:32], m5 = mag_data[47:40];
    wire [7:0] m6 = mag_data[55:48], m7 = mag_data[63:56], m8 = mag_data[71:64];
    wire [7:0] dir_center = dir_data[39:32];

    // Stage 1: compute all four and compares in parallel
    reg cmp_horiz, cmp_diag1, cmp_vert, cmp_diag2;
    reg [7:0] m4_r;
    reg [7:0] dir_r;
    reg v1;

    always @(posedge clk) begin
        cmp_horiz <= (m4 >= m3) && (m4 > m5);
        cmp_diag1 <= (m4 >= m2) && (m4 > m6);
        cmp_vert  <= (m4 >= m1) && (m4 > m7);
        cmp_diag2 <= (m4 >= m0) && (m4 > m8);
        m4_r      <= m4;
        dir_r     <= dir_center;
        v1        <= mag_valid;
    end

    // Stage 2: select based on registered dir, output
    always @(posedge clk) begin
        p_vld <= v1;
        if (v1) begin
            case (dir_r)
                8'd0: p_out <= cmp_horiz ? m4_r : 8'd0;
                8'd1: p_out <= cmp_diag1 ? m4_r : 8'd0;
                8'd2: p_out <= cmp_vert  ? m4_r : 8'd0;
                8'd3: p_out <= cmp_diag2 ? m4_r : 8'd0;
                default: p_out <= m4_r;
            endcase
        end
    end

endmodule
