module haar_classifier_stage #(
    parameter NUM_CLASSIFIERS = 3,           // Number of classifiers in this stage
    parameter NUM_RECTANGLES = 4,            // Number of rectangles per feature
    parameter IMG_WIDTH = 20,                // Width of the image
    parameter IMG_HEIGHT = 20,
    parameter THRESHOLD_STAGE = 100          
)(
    input clk,
    input reset,
    output reg stage_result
);

    integer c, r;     
    integer top_left_idx, top_right_idx, bottom_left_idx, bottom_right_idx;
    reg signed [15:0] A, B, C, D;
    reg integral_ready;
    reg [7:0] x_coord[NUM_CLASSIFIERS-1:0][NUM_RECTANGLES-1:0];
    reg [7:0] y_coord[NUM_CLASSIFIERS-1:0][NUM_RECTANGLES-1:0];
    reg [7:0] width[NUM_CLASSIFIERS-1:0][NUM_RECTANGLES-1:0];
    reg [7:0] height[NUM_CLASSIFIERS-1:0][NUM_RECTANGLES-1:0];
    reg signed [15:0] weight[NUM_CLASSIFIERS-1:0][NUM_RECTANGLES-1:0];
    reg signed [15:0] classifier_threshold[NUM_CLASSIFIERS-1:0];
    reg signed [15:0] classifier_value1[NUM_CLASSIFIERS-1:0];
    reg signed [15:0] classifier_value2[NUM_CLASSIFIERS-1:0];
    reg signed [15:0] accumulated_sum;
    reg signed [15:0] classifier_sum;
    reg signed [15:0] rectangle_sum;
    reg ena, wea;
    reg [8:0] addr;
    reg [16:0] integral_image [0:399];
    wire [16:0] din0;
    wire [16:0] dout0;

    // ILA signals for probing
    reg [16:0] probe_image; // Signal to send to ILA for the integral image
    reg [8:0] probe_addr;   // Current address for probing

    always @(posedge clk) begin
        if (reset) begin
            addr <= 0;
            wea <= 0;
            ena <= 1;
            integral_ready <= 0;

            // Initialize arrays
            x_coord[0][0] = 8'd3; x_coord[0][1] = 8'd3; x_coord[0][2] = 8'd0; x_coord[0][3] = 8'd0;
            x_coord[1][0] = 8'd1; x_coord[1][1] = 8'd7; x_coord[1][2] = 8'd0; x_coord[1][3] = 8'd0;
            x_coord[2][0] = 8'd1; x_coord[2][1] = 8'd1; x_coord[2][2] = 8'd0; x_coord[2][3] = 8'd0;

            y_coord[0][0] = 8'd7; y_coord[0][1] = 8'd9; y_coord[0][2] = 8'd0; y_coord[0][3] = 8'd0;
            y_coord[1][0] = 8'd2; y_coord[1][1] = 8'd2; y_coord[1][2] = 8'd0; y_coord[1][3] = 8'd0;
            y_coord[2][0] = 8'd7; y_coord[2][1] = 8'd10; y_coord[2][2] = 8'd0; y_coord[2][3] = 8'd0;

            width[0][0] = 8'd14; width[0][1] = 8'd14; width[0][2] = 8'd0; width[0][3] = 8'd0;
            width[1][0] = 8'd18; width[1][1] = 8'd6; width[1][2] = 8'd0; width[1][3] = 8'd0;
            width[2][0] = 8'd15; width[2][1] = 8'd15; width[2][2] = 8'd0; width[2][3] = 8'd0;

            height[0][0] = 8'd4; height[0][1] = 8'd2; height[0][2] = 8'd0; height[0][3] = 8'd0;
            height[1][0] = 8'd4; height[1][1] = 8'd4; height[1][2] = 8'd0; height[1][3] = 8'd0;
            height[2][0] = 8'd9; height[2][1] = 8'd3; height[2][2] = 8'd0; height[2][3] = 8'd0;

            weight[0][0] = -16'sd1; weight[0][1] = 16'sd2; weight[0][2] = 16'sd0; weight[0][3] = 16'sd0;
            weight[1][0] = -16'sd1; weight[1][1] = 16'sd3; weight[1][2] = 16'sd0; weight[1][3] = 16'sd0;
            weight[2][0] = -16'sd1; weight[2][1] = 16'sd3; weight[2][2] = 16'sd0; weight[2][3] = 16'sd0;

            classifier_threshold[0] = 16'd5;
            classifier_threshold[1] = 16'd10;
            classifier_threshold[2] = 16'd15;

            classifier_value1[0] = 16'd1;
            classifier_value1[1] = 16'd2;
            classifier_value1[2] = 16'd3;

            classifier_value2[0] = 16'd10;
            classifier_value2[1] = 16'd20;
            classifier_value2[2] = 16'd30;
        end else begin
            integral_image[addr] <= dout0;
            addr <= addr + 1;

            // Probing the integral_image and addr for ILA
            probe_image <= dout0; // Probing the output of blk_mem_gen
            probe_addr <= addr;   // Probing the current address

            if (addr == (IMG_WIDTH * IMG_HEIGHT - 1)) begin
                integral_ready <= 1;
            end
        end
    end

    blk_mem_gen_0 your_instance_name (
        .clka(clk),    
        .ena(ena),     
        .wea(wea),     
        .addra(addr),  
        .dina(din0),   
        .douta(dout0)  
    );      

    // ILA Instance
    ila_0 ila_name (
        .clk(clk),              // input wire clk
        .probe0(probe_image),  // Probe for integral image value
        .probe1(probe_addr)    // Probe for the current address
    );

    always @(posedge clk) begin
        if (reset) begin
            accumulated_sum <= 0;
            stage_result <= 0;
        end else if (integral_ready) begin
            accumulated_sum <= 0;

            for (c = 0; c < NUM_CLASSIFIERS; c = c + 1) begin
                classifier_sum = 0;

                for (r = 0; r < NUM_RECTANGLES; r = r + 1) begin
                    top_left_idx = x_coord[c][r] + (y_coord[c][r] * IMG_WIDTH);
                    top_right_idx = (x_coord[c][r] + width[c][r]) + (y_coord[c][r] * IMG_WIDTH);
                    bottom_left_idx = x_coord[c][r] + ((y_coord[c][r] + height[c][r]) * IMG_WIDTH);
                    bottom_right_idx = (x_coord[c][r] + width[c][r]) + ((y_coord[c][r] + height[c][r]) * IMG_WIDTH);

                    A = integral_image[top_left_idx];
                    B = integral_image[top_right_idx];
                    C = integral_image[bottom_left_idx];
                    D = integral_image[bottom_right_idx];

                    rectangle_sum = D - B - C + A; // Correct formula for rectangle sum
                    classifier_sum = classifier_sum + (rectangle_sum * weight[c][r]);
                    $display("Classifier Sum = %d", classifier_sum);
                end

                accumulated_sum = accumulated_sum + (classifier_sum >= classifier_threshold[c] ? classifier_value2[c] : classifier_value1[c]);
                $display("Accumulated Sum = %d", accumulated_sum);
            end

            stage_result <= (accumulated_sum >= THRESHOLD_STAGE);
        end
    end

endmodule