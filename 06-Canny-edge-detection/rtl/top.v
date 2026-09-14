module top #(
    parameter IMG_WIDTH = 320,  // 320x240
    parameter ADDR_WIDTH = 9   
)(
    input  pclk,        
    input  [7:0] p_in,  
    output p_out        
);

    // Internal Reset Generation
    reg [3:0] rst_cnt = 0;
    wire rst = ~&rst_cnt;
    always @(posedge pclk) begin
        if (rst) rst_cnt <= rst_cnt + 1'b1;
    end

    wire i_data_valid = ~rst; 

  
    wire [71:0] data_to_gb;
    wire        data_to_gb_valid;
    wire [7:0]  data_from_gb;
    wire        data_from_gb_valid;

    wire [71:0] data_to_sobel;
    wire        data_to_sobel_valid;
    wire [7:0]  mag_from_sobel;
    wire [7:0]  dir_from_sobel;
    wire        data_from_sobel_valid;

    wire [71:0] mag_to_nms;
    wire        mag_to_nms_valid;
    wire [71:0] dir_to_nms;
    wire        dir_to_nms_valid;

    wire [7:0]  data_from_nms;
    wire        data_from_nms_valid;

    wire [7:0]  data_from_dt;
    wire        data_from_dt_valid;

    wire [71:0] data_to_et;
    wire        data_to_et_valid;
    
    wire [7:0]  canny_out;
    wire        out_valid;

    // Line Buffer for Gaussian Blur
    imageControl #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .LINE_WIDTH(IMG_WIDTH)) IC1 (
        .i_clk(pclk),
        .i_rst(rst),
        .i_pixel_data(p_in),
        .i_pixel_data_valid(i_data_valid),
        .o_pixel_data(data_to_gb),
        .o_pixel_data_valid(data_to_gb_valid),
        .o_intr()
    );

    // Gaussian Blur Filter
    gaussianBlur gb (
        .clk(pclk),
        .rst(rst),
        .p_in(data_to_gb),
        .p_valid(data_to_gb_valid),
        .c_out(data_from_gb),
        .c_valid(data_from_gb_valid)
    );

    // Line Buffer for Sobel
    imageControl #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .LINE_WIDTH(IMG_WIDTH)) IC2 (
        .i_clk(pclk),
        .i_rst(rst),
        .i_pixel_data(data_from_gb),
        .i_pixel_data_valid(data_from_gb_valid),
        .o_pixel_data(data_to_sobel),
        .o_pixel_data_valid(data_to_sobel_valid),
        .o_intr()
    );

    // Sobel Filter
    sobel s1 (
        .clk(pclk),
        .rst(rst),
        .p_in(data_to_sobel),
        .p_valid(data_to_sobel_valid),
        .mag(mag_from_sobel),
        .dir(dir_from_sobel),
        .c_valid(data_from_sobel_valid)
    );

    // Magnitude Line Buffer for NMS
    imageControl #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .LINE_WIDTH(IMG_WIDTH)) IC3 (
        .i_clk(pclk),
        .i_rst(rst),
        .i_pixel_data(mag_from_sobel),
        .i_pixel_data_valid(data_from_sobel_valid),
        .o_pixel_data(mag_to_nms),
        .o_pixel_data_valid(mag_to_nms_valid),
        .o_intr()
    );

    // Direction Line Buffer for NMS
    imageControl #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .LINE_WIDTH(IMG_WIDTH)) IC4 (
        .i_clk(pclk),
        .i_rst(rst),
        .i_pixel_data(dir_from_sobel),
        .i_pixel_data_valid(data_from_sobel_valid),
        .o_pixel_data(dir_to_nms),
        .o_pixel_data_valid(dir_to_nms_valid),
        .o_intr()
    );

    // Non-Maximum Suppression
    non_max_suppr n1 (
        .clk(pclk),
        .mag_data(mag_to_nms),
        .mag_valid(mag_to_nms_valid),
        .dir_data(dir_to_nms),
        .dir_valid(dir_to_nms_valid),
        .p_out(data_from_nms),
        .p_vld(data_from_nms_valid)
    );

    // Double Thresholding
    double_threshold dt1 (
        .clk(pclk),
        .data_in(data_from_nms),
        .data_in_valid(data_from_nms_valid),
        .data_out(data_from_dt),
        .data_out_valid(data_from_dt_valid)
    );

    // Line Buffer for Edge Tracking
    imageControl #(.DATA_WIDTH(8), .ADDR_WIDTH(ADDR_WIDTH), .LINE_WIDTH(IMG_WIDTH)) IC5 (
        .i_clk(pclk),
        .i_rst(rst),
        .i_pixel_data(data_from_dt),
        .i_pixel_data_valid(data_from_dt_valid),
        .o_pixel_data(data_to_et),
        .o_pixel_data_valid(data_to_et_valid),
        .o_intr()
    );

    // Edge Tracking
    edge_track et1 (
        .clk(pclk),
        .data_in(data_to_et),
        .data_in_valid(data_to_et_valid),
        .data_out(canny_out),
        .data_out_valid(out_valid)
    );

    // 8-bit output to 1-bit
    assign p_out = (canny_out > 8'd0) ? 1'b1 : 1'b0;

endmodule
