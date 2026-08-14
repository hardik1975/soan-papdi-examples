module top (
    input clk,         
    input echo,         
    output trig,         
    output reg [7:0] leds  
);

    wire [31:0] captured_count;
    wire object_detected;

    ultrasonic_sensor #(
        .CLK_FREQ(12000000),
        .TRIG_PULSE_US(10),
        .MAX_DIST_CM(40)
    ) inst (
        .clk(clk),
        .echo(echo),
        .trig(trig),
        .captured_count(captured_count),
        .object_detected(object_detected)
    );

    reg echo_prev = 0;
    always @(posedge clk) echo_prev <= echo;
    wire echo_edge = ~echo_prev && echo;

   
    reg [21:0] timeout_counter = 0;
    localparam TIMEOUT_LIMIT = 12_000_000 / 10; // 100 ms

    always @(posedge clk) begin
        if (echo_edge) begin
            timeout_counter <= 0;
        end else if (timeout_counter < TIMEOUT_LIMIT) begin
            timeout_counter <= timeout_counter + 1;
        end
    end

    always @(posedge clk) begin
        if ((timeout_counter >= TIMEOUT_LIMIT) || !object_detected) begin
            leds <= 8'b00000000; 
        end else begin
            if (captured_count <= 3500)  leds <= 8'b11111111; 
            else if (captured_count <= 7000)  leds <= 8'b01111111; 
            else if (captured_count <= 10500) leds <= 8'b00111111; 
            else if (captured_count <= 14000) leds <= 8'b00011111; 
            else if (captured_count <= 17500) leds <= 8'b00001111; 
            else if (captured_count <= 21000) leds <= 8'b00000111; 
            else if (captured_count <= 24500) leds <= 8'b00000011; 
            else                              leds <= 8'b00000001; 
        end
    end

endmodule
