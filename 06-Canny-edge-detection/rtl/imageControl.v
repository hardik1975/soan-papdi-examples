module imageControl #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 9,
    parameter LINE_WIDTH = 320 
)(
    input  wire                  i_clk,
    input  wire                  i_rst,
    input  wire [DATA_WIDTH-1:0] i_pixel_data,
    input  wire                  i_pixel_data_valid,
    output reg  [71:0]           o_pixel_data,
    output reg                   o_pixel_data_valid,
    output reg                   o_intr
);

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    wire [DATA_WIDTH-1:0] lb1_data_out;
    wire [DATA_WIDTH-1:0] lb2_data_out;

    reg [DATA_WIDTH-1:0] r0 [0:2];
    reg [DATA_WIDTH-1:0] r1 [0:2];
    reg [DATA_WIDTH-1:0] r2 [0:2];

    reg [ADDR_WIDTH-1:0] pixel_cnt;
    reg [1:0]            line_cnt;
    reg                  new_line_r; 

    lineBuffer #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) lB1 (
        .clk(i_clk), .wr_en(i_pixel_data_valid), .wr_addr(wr_ptr), .wr_data(i_pixel_data),
        .rd_en(i_pixel_data_valid), .rd_addr(rd_ptr), .rd_data(lb1_data_out)
    );
    
    lineBuffer #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) lB2 (
        .clk(i_clk), .wr_en(i_pixel_data_valid), .wr_addr(wr_ptr), .wr_data(lb1_data_out),
        .rd_en(i_pixel_data_valid), .rd_addr(rd_ptr), .rd_data(lb2_data_out)
    );

    wire end_of_line = (pixel_cnt == LINE_WIDTH - 1); 
    
    // Row (top-border) replication
    wire [DATA_WIDTH-1:0] r1_src = (line_cnt == 2'd0) ? i_pixel_data : lb1_data_out;
    wire [DATA_WIDTH-1:0] r0_src = (line_cnt <= 2'd1) ? r1_src       : lb2_data_out;
    wire [DATA_WIDTH-1:0] r2_src = i_pixel_data;

    always @(posedge i_clk) begin
        if (i_rst) begin
            wr_ptr             <= {ADDR_WIDTH{1'b0}};
            rd_ptr             <= {ADDR_WIDTH{1'b0}};
            pixel_cnt          <= {ADDR_WIDTH{1'b0}};
            line_cnt           <= 2'd0;
            new_line_r         <= 1'b1;    // frame's first pixel is a new line
            o_pixel_data_valid <= 1'b0;
            o_intr             <= 1'b0;
        end else if (i_pixel_data_valid) begin
            wr_ptr <= wr_ptr + 1'b1;
            rd_ptr <= wr_ptr;
            
            
            // Column (left-border) replication 
            if (new_line_r) begin
                r0[0] <= r0_src; r0[1] <= r0_src; r0[2] <= r0_src;
                r1[0] <= r1_src; r1[1] <= r1_src; r1[2] <= r1_src;
                r2[0] <= r2_src; r2[1] <= r2_src; r2[2] <= r2_src;
            end else begin
                r0[0] <= r0[1]; r0[1] <= r0[2]; r0[2] <= r0_src;
                r1[0] <= r1[1]; r1[1] <= r1[2]; r1[2] <= r1_src;
                r2[0] <= r2[1]; r2[1] <= r2[2]; r2[2] <= r2_src;
            end

            pixel_cnt  <= end_of_line ? {ADDR_WIDTH{1'b0}} : pixel_cnt + 1'b1;
            new_line_r <= end_of_line;
            if (end_of_line && line_cnt < 2'd2)
                line_cnt <= line_cnt + 1'b1;

            o_pixel_data <= {r0[0],r0[1],r0[2], r1[0],r1[1],r1[2], r2[0],r2[1],r2[2]};
            o_pixel_data_valid <= 1'b1;
        end else begin
            o_pixel_data_valid <= 1'b0;
        end
    end
endmodule
