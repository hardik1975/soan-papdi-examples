
module cordic_circular (
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire signed [15:0] angle_in,  
    output reg  signed [15:0] cos_out,  
    output reg  signed [15:0] sin_out,   
    output reg                done
);

    localparam signed [15:0] HALF_PI  = 16'sd16384; 
    localparam signed [15:0] K_FACTOR = 16'sd19898;  

reg signed [17:0] x, y, z;
reg [3:0] i;
reg [1:0] state;

wire signed [17:0] norm_angle = $signed({{2{angle_in[15]}}, angle_in});

localparam IDLE   = 2'd0;
localparam ROTATE = 2'd1;
localparam DONE   = 2'd2;


function signed [15:0] sat;
        input signed [17:0] val;
        begin
            if (val > 18'sd32767)
                sat = 16'sd32767;
            else if (val < -18'sd32768)
                sat = -16'sd32768;
            else
                sat = val[15:0];
        end
    endfunction


reg signed [15:0] atan;
always@(*)begin
    case(i)
            4'd0:  atan = 16'sd8192; // 45.000 deg
            4'd1:  atan = 16'sd4836; // 26.565 deg
            4'd2:  atan = 16'sd2555; // 14.036 deg
            4'd3:  atan = 16'sd1297; //  7.125 deg
            4'd4:  atan = 16'sd651;  //  3.576 deg
            4'd5:  atan = 16'sd326;  //  1.790 deg
            4'd6:  atan = 16'sd163;  //  0.895 deg
            4'd7:  atan = 16'sd81;   //  0.448 deg
            4'd8:  atan = 16'sd41;   //  0.224 deg
            4'd9:  atan = 16'sd20;   //  0.112 deg
            4'd10: atan = 16'sd10;
            4'd11: atan = 16'sd5;
            4'd12: atan = 16'sd3;
            4'd13: atan = 16'sd1;
            4'd14: atan = 16'sd1;
            default: atan = 16'sd0;
            endcase
    end
    
wire signed [17:0] x_shift = x >>> i;
wire signed [17:0] y_shift = y >>> i;    

always@(posedge clk)begin
if(rst) begin
state<=IDLE;
cos_out <= 16'sd0;
sin_out <= 16'sd0;
done <= 1'b0;
x <= 18'sd0;
y <= 18'sd0;
z <= 18'sd0;
i <= 4'd0;

end 
else begin
case (state)
       IDLE: begin
       done <= 1'b0;
       if (start) begin
       i     <= 4'd0;
       state <= ROTATE;
              
         
              
       if (norm_angle > HALF_PI) begin
       x <= 18'sd0;
       y <= $signed(K_FACTOR);
       z <= norm_angle - HALF_PI;
       end
       else if (norm_angle < -HALF_PI) begin
       x <= 18'sd0;
       y <= -$signed(K_FACTOR);
       z <= norm_angle + HALF_PI;
       end 
       else begin
       x <= $signed(K_FACTOR);
       y <= 18'sd0;
       z <= norm_angle;
       end
       end
       end
       
       ROTATE: begin
                    
       if (z >= 0) begin
       x <= x - y_shift;
       y <= y + x_shift;
       z <= z - $signed(atan);
       end 
       else begin
       x <= x + y_shift;
       y <= y - x_shift;
       z <= z + $signed(atan);
       end

       if (i == 4'd14) begin
       state <= DONE;
       end else begin
       i <= i + 4'd1;
       end
       end
       
       DONE: begin
cos_out <= sat(x);
sin_out <= sat(y);
       done    <= 1'b1;
       state   <= IDLE;
       end

       default: state <= IDLE;
endcase
end
end

endmodule
