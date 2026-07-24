module servo_sweep (
    input  wire clk,
    output reg  servo
);

    // 12MHz clock
    // 50Hz servo signal = 20ms period
    localparam PERIOD = 240000;

    // Servo range
    localparam MIN_PULSE = 6000;   // 0.5ms (~0 degree)
    localparam MAX_PULSE = 30000;  // 2.5ms (~180 degree)

    reg [17:0] pwm_counter = 0;
    reg [15:0] pulse_width = MIN_PULSE;
    reg direction = 1'b1;

    // Controls movement speed
    reg [20:0] speed_counter = 0;

    always @(posedge clk) begin

        // PWM counter
        if (pwm_counter >= PERIOD-1)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;

        // Servo PWM output
        if (pwm_counter < pulse_width)
            servo <= 1'b1;
        else
            servo <= 1'b0;

        // Update angle quickly
        if (speed_counter >= 240000) begin
            speed_counter <= 0;

            if(direction) begin
                // Move 0 -> 180
                if(pulse_width < MAX_PULSE)
                    pulse_width <= pulse_width + 200;
                else
                    direction <= 0;

            end else begin
                // Move 180 -> 0
                if(pulse_width > MIN_PULSE)
                    pulse_width <= pulse_width - 200;
                else
                    direction <= 1;

            end

        end else begin
            speed_counter <= speed_counter + 1;
        end

    end

endmodule