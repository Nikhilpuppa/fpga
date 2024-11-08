module haar_classifier_stage #(
    parameter int NUM_CLASSIFIERS = 3,           // Number of classifiers in this stage
    parameter int NUM_RECTANGLES = 4,            // Number of rectangles per feature
    parameter int IMG_WIDTH = 20,                // Width of the image
    parameter int IMG_HEIGHT = 20,
    parameter int THRESHOLD_STAGE = 100         
)(
    input  logic clk,
    input  logic reset,
    // Output rectangle sum
    output logic stage_result
);

    int c, r;     
    logic signed [15:0] A, B, C, D;   
    logic [7:0] x_coord[NUM_CLASSIFIERS][NUM_RECTANGLES];
    logic [7:0] y_coord[NUM_CLASSIFIERS][NUM_RECTANGLES];
    logic [7:0] width[NUM_CLASSIFIERS][NUM_RECTANGLES]; 
    logic [7:0] height[NUM_CLASSIFIERS][NUM_RECTANGLES];
    logic signed [15:0] weight[NUM_CLASSIFIERS][NUM_RECTANGLES]; 
    logic [15:0] integral_image[IMG_WIDTH-1:0][IMG_HEIGHT-1:0];
    logic signed [15:0] classifier_threshold[NUM_CLASSIFIERS];
    logic signed [15:0] classifier_value1[NUM_CLASSIFIERS]; 
    logic signed [15:0] classifier_value2[NUM_CLASSIFIERS];
    logic signed [15:0] accumulated_sum;
    logic signed [15:0] classifier_sum;  // Output classifier sum instead of internal declaration
    logic signed [15:0] rectangle_sum; 

initial begin
    // Initialize x_coord
    x_coord[0] = {8'd3, 8'd3, 8'd0, 8'd0};
    x_coord[1] = {8'd1, 8'd7, 8'd0, 8'd0};
    x_coord[2] = {8'd1, 8'd1, 8'd0, 8'd0};

    // Initialize y_coord
    y_coord[0] = {8'd7, 8'd9, 8'd0, 8'd0};
    y_coord[1] = {8'd2, 8'd2, 8'd0, 8'd0};
    y_coord[2] = {8'd7, 8'd10, 8'd0, 8'd0};

    // Initialize width
    width[0] = {8'd14, 8'd14, 8'd0, 8'd0};
    width[1] = {8'd18, 8'd6, 8'd0, 8'd0};
    width[2] = {8'd15, 8'd15, 8'd0, 8'd0};

    // Initialize height
    height[0] = {8'd4, 8'd2, 8'd0, 8'd0};
    height[1] = {8'd4, 8'd4, 8'd0, 8'd0};
    height[2] = {8'd9, 8'd3, 8'd0, 8'd0};

    // Initialize weight
    weight[0] = {-16'sd1, 16'sd2, 16'sd0, 16'sd0};
    weight[1] = {-16'sd1, 16'sd3, 16'sd0, 16'sd0};
    weight[2] = {-16'sd1, 16'sd3, 16'sd0, 16'sd0};

    for (int i = 0; i < IMG_WIDTH; i++) begin
        for (int j = 0; j < IMG_HEIGHT; j++) begin
            integral_image[i][j] = 16'd0 + (i+j); 
        end
    end

    // Initialize classifier_threshold
    classifier_threshold[0] = 16'd5;
    classifier_threshold[1] = 16'd10;
    classifier_threshold[2] = 16'd15;

    // Initialize classifier_value1
    classifier_value1[0] = 16'd1;
    classifier_value1[1] = 16'd2;
    classifier_value1[2] = 16'd3;

    // Initialize classifier_value2
    classifier_value2[0] = 16'd10;
    classifier_value2[1] = 16'd20;
    classifier_value2[2] = 16'd30;
end

    // ILA instance (assume it's used for debugging)
    ila_0 your_instance_name (
        .clk(clk),
        .probe0(rectangle_sum),
        .probe1(accumulated_sum),
        .probe2(classifier_sum)
    );         
    
    always_ff @(posedge clk) begin
        if (reset) begin
            accumulated_sum <= 0;
            stage_result <= 0;
        end else begin
            accumulated_sum <= 0; // Reset the accumulated sum for each stage calculation
            
            for (r = 0; r < NUM_CLASSIFIERS; r++) begin
                classifier_sum = 0; // Initialize classifier sum to zero at the beginning of each classifier loop

                for (c = 0; c < NUM_RECTANGLES; c++) begin
                    A = integral_image[x_coord[r][c]][y_coord[r][c]];                             // Top-left
                    B = integral_image[x_coord[r][c] + width[r][c]][y_coord[r][c]];            // Top-right
                    C = integral_image[x_coord[r][c]][y_coord[r][c] + height[r][c]];           // Bottom-left
                    D = integral_image[x_coord[r][c] + width[r][c]][y_coord[r][c] + height[r][c]]; // Bottom-right

                    rectangle_sum = D + B + C + A; // Calculate rectangle sum

                    classifier_sum = classifier_sum + (rectangle_sum * weight[r][c]); // Accumulate weighted sum
                    $display("Classifier Sum = %d", classifier_sum);
                end

                // Update accumulated sum based on classifier results
                accumulated_sum = accumulated_sum + (classifier_sum >= classifier_threshold[r] ? classifier_value2[r] : classifier_value1[r]);
                 $display("Accumulated Sum = %d", accumulated_sum);
            end
            
            // Determine if the stage passes or fails
            stage_result <= (accumulated_sum >= THRESHOLD_STAGE);
        end
    end

endmodule
