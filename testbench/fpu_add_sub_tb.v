// Test bench for FPU Addition/Subtraction Module

`timescale 1ns/1ps

module fpu_add_sub_tb;

    // Test signals
    reg  [31:0] a;
    reg  [31:0] b;
    reg         sub;
    wire [31:0] result;
    wire        overflow;
    wire        underflow;
    wire        invalid;
    
    // Instantiate module
    fpu_add_sub uut (
        .a(a),
        .b(b),
        .sub(sub),
        .result(result),
        .overflow(overflow),
        .underflow(underflow),
        .invalid(invalid)
    );
    
    // Test task
    task test_operation;
        input [31:0] in_a;
        input [31:0] in_b;
        input        is_sub;
        input [8*10:1] op_name;
        begin
            a = in_a;
            b = in_b;
            sub = is_sub;
            #10;
            $display("%s: %h %s %h = %h (OV=%b, UN=%b, INV=%b)",
                     op_name, a, is_sub ? "-" : "+", b, result, 
                     overflow, underflow, invalid);
        end
    endtask
    
    initial begin
        $display("=== FPU Add/Sub Module Test ===\n");
        
        // Addition tests
        $display("--- Addition Tests ---");
        test_operation(32'h40400000, 32'h40000000, 1'b0, "ADD");  // 3.0 + 2.0
        test_operation(32'h3F800000, 32'h3F800000, 1'b0, "ADD");  // 1.0 + 1.0
        test_operation(32'h00000000, 32'h3F800000, 1'b0, "ADD");  // 0.0 + 1.0
        
        // Subtraction tests
        $display("\n--- Subtraction Tests ---");
        test_operation(32'h40A00000, 32'h40000000, 1'b1, "SUB");  // 5.0 - 2.0
        test_operation(32'h40400000, 32'h40400000, 1'b1, "SUB");  // 3.0 - 3.0
        
        // Special cases
        $display("\n--- Special Cases ---");
        test_operation(32'h7F800000, 32'h40000000, 1'b0, "ADD");  // Inf + 2.0
        test_operation(32'h7FC00000, 32'h40000000, 1'b0, "ADD");  // NaN + 2.0
        
        #10;
        $display("\n=== Test Complete ===");
        $finish;
    end

endmodule
