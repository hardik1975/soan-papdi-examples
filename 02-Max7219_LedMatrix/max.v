module max (
    input clk,
    input rst,
    input [7:0] row0,
    input [7:0] row1,
    input [7:0] row2,
    input [7:0] row3,
    input [7:0] row4,
    input [7:0] row5,
    input [7:0] row6,
    input [7:0] row7,
    output reg din,
    output reg sclk,
    output reg cs
);

    // spi shift logic
    reg [15:0] shift;
    reg [4:0] bits;
    reg [1:0] tick;
    reg shift_state;
    reg send;
    reg [7:0] addr;
    reg [7:0] data;
    reg busy;

    always @(posedge clk) begin
        if (rst) begin
            cs <= 1;
            sclk <= 0;
            busy <= 0;
            shift_state <= 0;
        end else begin
            case (shift_state)
                0: begin
                    if (send) begin
                        shift <= {addr, data};
                        bits <= 0;
                        cs <= 0;
                        busy <= 1;
                        shift_state <= 1;
                        tick <= 0;
                    end
                end
                1: begin
                    tick <= tick + 1;
                    case (tick)
                        0: begin
                            din <= shift[15];
                            sclk <= 0;
                        end
                        2: sclk <= 1;
                        3: begin
                            shift <= shift << 1;
                            bits <= bits + 1;
                            if (bits == 15) begin
                                cs <= 1;
                                busy <= 0;
                                shift_state <= 0;
                            end
                        end
                    endcase
                end
            endcase
        end
    end

    // init and refresh sequencer
    localparam init_decode   = 8'h09;
    localparam init_scanlim  = 8'h0B;
    localparam init_shutdown = 8'h0C;
    localparam init_intens   = 8'h0A;
    localparam init_test     = 8'h0F;
    localparam row_base      = 8'h01;

    localparam s_idle     = 0;
    localparam s_scanlim  = 1;
    localparam s_shutdown = 2;
    localparam s_intens   = 3;
    localparam s_test     = 4;
    localparam s_row      = 5;
    localparam s_wait     = 6;
    localparam s_run      = 7;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [3:0] row_index;

    always @(posedge clk) begin
        if (rst) begin
            state <= s_idle;
            row_index <= 0;
            send <= 0;
        end else begin
            send <= 0;

            case (state)
                s_idle: begin
                    addr <= init_decode;
                    data <= 8'h00;
                    send <= 1;
                    state <= s_wait;
                    next_state <= s_scanlim;
                end

                s_scanlim: begin
                    addr <= init_scanlim;
                    data <= 8'h07;
                    send <= 1;
                    state <= s_wait;
                    next_state <= s_shutdown;
                end

                s_shutdown: begin
                    addr <= init_shutdown;
                    data <= 8'h01;
                    send <= 1;
                    state <= s_wait;
                    next_state <= s_intens;
                end

                s_intens: begin
                    addr <= init_intens;
                    data <= 8'h08;
                    send <= 1;
                    state <= s_wait;
                    next_state <= s_test;
                end

                s_test: begin
                    addr <= init_test;
                    data <= 8'h00;
                    send <= 1;
                    state <= s_wait;
                    next_state <= s_row;
                    row_index <= 0;
                end

                s_row: begin
                    addr <= row_base + row_index;
                    case (row_index)
                        0: data <= row0;
                        1: data <= row1;
                        2: data <= row2;
                        3: data <= row3;
                        4: data <= row4;
                        5: data <= row5;
                        6: data <= row6;
                        7: data <= row7;
                    endcase
                    send <= 1;
                    state <= s_wait;
                    if (row_index == 7)
                        next_state <= s_run;
                    else
                        next_state <= s_row;
                end

                s_wait: begin
                    if (!busy && !send) begin
                        if (next_state == s_row)
                            row_index <= row_index + 1;
                        state <= next_state;
                    end
                end

                s_run: begin
                    // keep looping so any change in row0 to row7 shows up live
                    row_index <= 0;
                    state <= s_row;
                end

                default: state <= s_idle;
            endcase
        end
    end

endmodule
