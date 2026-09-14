module edge_track(
    input clk,
    input [71:0] data_in,
    input data_in_valid,
    output reg [7:0] data_out,
    output data_out_valid
    );
    
    assign data_out_valid = data_in_valid;
    wire [7:0] center = data_in[39:32];

    always @(posedge clk) begin
        if (center == 255) begin
            data_out <= 8'd255;
        end else if (center > 0) begin // Evaluates weak edges
            if (data_in[7:0] == 255 || data_in[15:8] == 255 || data_in[23:16] == 255 || 
                data_in[31:24] == 255 || data_in[47:40] == 255 || data_in[55:48] == 255 || 
                data_in[63:56] == 255 || data_in[71:64] == 255)
                data_out <= 8'd255;
            else
                data_out <= 8'd0;
        end else begin
            data_out <= 8'd0;      
        end
    end
endmodule
