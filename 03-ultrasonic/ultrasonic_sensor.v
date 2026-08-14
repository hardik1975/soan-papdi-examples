module ultrasonic_sensor #(
	parameter CLK_FREQ      = 12000000,  
	parameter TRIG_PULSE_US = 10,
	parameter MAX_DIST_CM   = 40        
) (
    input clk,
    input echo,
    output reg trig,
    output reg [31:0] captured_count,     
    output reg object_detected
);

// MAX_COUNT = (MAX_DIST_CM * 2 * CLK_FREQ) / 34300
localparam MAX_COUNT = (MAX_DIST_CM * 2 * CLK_FREQ) / 34300; 
localparam DEBOUNCE_CNT_LIMIT = 120_000; 

reg [31:0] echo_cnt = 0;
reg echo_prev = 0;
reg [31:0] trig_cnt = 0;
reg detect = 0;

reg [31:0] debounce_clk_cnt = 0;

always @(posedge clk) begin
    if(trig_cnt < (CLK_FREQ * 60 / 1000)) begin
      trig_cnt <= trig_cnt + 1;
    end else begin
        trig_cnt <= 0;
    end
    if (trig_cnt < (TRIG_PULSE_US * (CLK_FREQ / 1_000_000)))
        trig <= 1;
    else
        trig <= 0;
end


always @(posedge clk) begin
    echo_prev <= echo;
    if (~echo_prev && echo) begin
        echo_count <= 0;
    end
    else if (echo) begin
        echo_count <= echo_count + 1;
    end
    if (echo_prev && ~echo) begin
        if (echo_cnt <= MAX_COUNT) begin
        detect <= 1;
            captured_count <= echo_cnt;
        end else begin
          detect <= 0;
         captured_count <= MAX_COUNT + 1;
        end
    end
end
always @(posedge clk) begin
    if ((object_detected != detect) && (debounce_clk_cnt < DEBOUNCE_CNT_LIMIT)) begin
    debounce_clk_cnt <= debounce_clk_cnt + 1;
    end
    else if (debounce_clk_cnt == DEBOUNCE_CNT_LIMIT) begin
        object_detected <= detect;
     debounce_clk_cnt <= 0;
    end 
    else begin
        debounce_clk_cnt <= 0;
    end
end
endmodule
