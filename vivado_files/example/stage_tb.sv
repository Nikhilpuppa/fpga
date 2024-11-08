module tb_haar_classifier_stage;

    // Parameters for the module under test
    parameter int NUM_CLASSIFIERS = 3;
    parameter int NUM_RECTANGLES = 4;
    parameter int IMG_WIDTH = 20;
    parameter int IMG_HEIGHT = 20;
    parameter int THRESHOLD_STAGE = 100;

    // Testbench signals
    logic clk;
    logic reset;
    logic signed [15:0] accumulated_sum;
    logic signed [15:0] classifier_sum;
    logic signed [15:0] rectangle_sum;
    logic stage_result;

    // Instantiate the haar_classifier_stage module
    haar_classifier_stage #(
        .NUM_CLASSIFIERS(NUM_CLASSIFIERS),
        .NUM_RECTANGLES(NUM_RECTANGLES),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .THRESHOLD_STAGE(THRESHOLD_STAGE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .stage_result(stage_result)
    );

    // Generate clock signal
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    // Test sequence
    initial begin
        // Apply reset
        reset = 1;
        #10;
        reset = 0;
        #10;

        // Wait for calculations to proceed
        @(posedge clk);
        #50;

        // Display the values to observe functionality
        $display("Test 1: Initial Test Case");
        $display("Accumulated Sum = %d", accumulated_sum);
        $display("Classifier Sum = %d", classifier_sum);
        $display("Rectangle Sum = %d", rectangle_sum);
        $display("Stage Result = %b", stage_result);

        // Additional checks can be placed here for specific expected results
        // Example: if expected result is known, add checks for pass/fail
        if (stage_result == 1) 
            $display("Stage passed threshold.");
        else 
            $display("Stage failed threshold.");

        // Finish the simulation
        #100;
        $finish;
    end

endmodule
