`timescale 1ns/1ps

module tb_top;

    parameter WIDTH        = 320;
    parameter HEIGHT       = 240;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT; // 76,800

    reg pclk;
    reg [7:0] p_in;
    wire p_out;

    reg [7:0] img_in [0:TOTAL_PIXELS-1];
    integer in_file, out_file;
    integer p;
    integer pixels_written = 0;
    integer input_pixel_count = 0;
    integer bytes_read;
    reg first_valid_seen = 0;

    reg [7:0] bit_buf = 0;
    integer bit_cnt = 0;

    // Instantiate Top Module
    top #(
        .IMG_WIDTH(WIDTH),
        .ADDR_WIDTH(9)
    ) uut (
        .pclk(pclk),
        .p_in(p_in),
        .p_out(p_out)
    );

    // Clock Generation (50 MHz)
    always #10 pclk = ~pclk;

    // Monitor Input and Output Latency
    always @(posedge pclk) begin
        // Corrected uut.p_valid -> uut.i_data_valid
        if (uut.i_data_valid) begin
            input_pixel_count <= input_pixel_count + 1;
        end
            
        if (uut.out_valid && !first_valid_seen) begin
            first_valid_seen <= 1'b1;
            $display("[INFO] First valid pixel output at input pixel count: %0d", input_pixel_count);
        end
    end

    // Output Packing and File Writing
    always @(negedge pclk) begin
        if (uut.out_valid && pixels_written < TOTAL_PIXELS) begin
            bit_buf = (bit_buf >> 1) | (p_out << 7);
            bit_cnt = bit_cnt + 1;
            pixels_written = pixels_written + 1;

            if (bit_cnt == 8) begin
                $fwrite(out_file, "%c", bit_buf);
                bit_cnt = 0;
                bit_buf = 0;
            end
        end
    end

    // Main Test Stimulus
    initial begin
        pclk = 0;
        p_in = 8'd0;

        // Open Input Binary File
        in_file = $fopen("input.bin", "rb");
        if (!in_file) begin
            $display("[ERROR] Could not open 'input.bin'. Ensure the file exists in the simulation run directory.");
            $finish;
        end
        
        bytes_read = $fread(img_in, in_file);
        $display("[INFO] Read %0d bytes from input.bin", bytes_read);
        $fclose(in_file);

        // Open Output Binary File 
        out_file = $fopen("output.bin", "wb");

        // Wait for internal reset generation (rst_cnt counts up to 15)
        #400; 

        // Stream Pixels into DUT
        for (p = 0; p < TOTAL_PIXELS; p = p + 1) begin
            p_in = img_in[p];
            @(negedge pclk); 
        end

        // Stream zeros while waiting for pipeline flushing
        p_in = 8'd0;
        while (pixels_written < TOTAL_PIXELS) begin
            @(negedge pclk);
        end

        // Flush remaining bits if total output bit count is not aligned to full bytes
        if (bit_cnt > 0) begin
            bit_buf = bit_buf >> (8 - bit_cnt);
            $fwrite(out_file, "%c", bit_buf);
        end

        $fclose(out_file);
        $display("[SUCCESS] Processing Complete. Total output pixels processed: %0d", pixels_written);
        $finish;
    end

endmodule
