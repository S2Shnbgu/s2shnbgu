// Test bench for IEEE 754 Floating Point Unit

`timescale 1ns/1ps

module fpu_tb;

    // Test signals
    reg         clk;
    reg         rst;
    reg  [31:0] operand_a;
    reg  [31:0] operand_b;
    reg  [1:0]  operation;
    reg         start;
    wire [31:0] result;
    wire        ready;
    wire        overflow;
    wire        underflow;
    wire        invalid;
    
    // Operation codes
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_MUL = 2'b10;
    localparam OP_DIV = 2'b11;
    
    // Instantiate FPU
    fpu uut (
        .clk(clk),
        .rst(rst),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .start(start),
        .result(result),
        .ready(ready),
        .overflow(overflow),
        .underflow(underflow),
        .invalid(invalid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end
    
    // Test task
    task perform_operation;
        input [31:0] a;
        input [31:0] b;
        input [1:0]  op;
        input [8*20:1] op_name;
        begin
            @(posedge clk);
            operand_a = a;
            operand_b = b;
            operation = op;
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
            
            // Wait for operation to complete
            @(posedge ready);
            @(posedge clk);
            
            $display("%s: %h %s %h = %h (overflow=%b, underflow=%b, invalid=%b)",
                     op_name, a, op_name, b, result, overflow, underflow, invalid);
        end
    endtask
    
    // Helper function to convert float to hex (IEEE 754)
    function [31:0] float_to_hex;
        input real value;
        reg [31:0] result_val;
        real abs_val;
        integer exp;
        real mant;
        integer mant_int;
        begin
            if (value == 0.0) begin
                float_to_hex = 32'h00000000;
            end else begin
                result_val[31] = (value < 0.0) ? 1'b1 : 1'b0;
                abs_val = (value < 0.0) ? -value : value;
                
                // Calculate exponent and mantissa (simplified)
                exp = 127;
                mant = abs_val;
                
                while (mant >= 2.0) begin
                    mant = mant / 2.0;
                    exp = exp + 1;
                end
                
                while (mant < 1.0) begin
                    mant = mant * 2.0;
                    exp = exp - 1;
                end
                
                result_val[30:23] = exp[7:0];
                mant_int = (mant - 1.0) * 8388608.0;  // 2^23
                result_val[22:0] = mant_int[22:0];
                
                float_to_hex = result_val;
            end
        end
    endfunction
    
    // Test sequence
    initial begin
        $display("=== IEEE 754 Floating Point Unit Test Bench ===");
        $display("Time\tOperation\tInputs\t\t\tResult");
        
        // Initialize
        rst = 1;
        start = 0;
        operand_a = 0;
        operand_b = 0;
        operation = 0;
        
        #20;
        rst = 0;
        #20;
        
        // Test Addition
        $display("\n--- Addition Tests ---");
        perform_operation(32'h40400000, 32'h40000000, OP_ADD, "ADD");  // 3.0 + 2.0 = 5.0
        perform_operation(32'h3F800000, 32'h3F800000, OP_ADD, "ADD");  // 1.0 + 1.0 = 2.0
        perform_operation(32'h41200000, 32'h40A00000, OP_ADD, "ADD");  // 10.0 + 5.0 = 15.0
        perform_operation(32'h00000000, 32'h3F800000, OP_ADD, "ADD");  // 0.0 + 1.0 = 1.0
        
        // Test Subtraction
        $display("\n--- Subtraction Tests ---");
        perform_operation(32'h40A00000, 32'h40000000, OP_SUB, "SUB");  // 5.0 - 2.0 = 3.0
        perform_operation(32'h40400000, 32'h40400000, OP_SUB, "SUB");  // 3.0 - 3.0 = 0.0
        perform_operation(32'h41200000, 32'h40A00000, OP_SUB, "SUB");  // 10.0 - 5.0 = 5.0
        
        // Test Multiplication
        $display("\n--- Multiplication Tests ---");
        perform_operation(32'h40000000, 32'h40400000, OP_MUL, "MUL");  // 2.0 * 3.0 = 6.0
        perform_operation(32'h3F800000, 32'h40A00000, OP_MUL, "MUL");  // 1.0 * 5.0 = 5.0
        perform_operation(32'h40000000, 32'h40000000, OP_MUL, "MUL");  // 2.0 * 2.0 = 4.0
        perform_operation(32'h00000000, 32'h40A00000, OP_MUL, "MUL");  // 0.0 * 5.0 = 0.0
        
        // Test Division
        $display("\n--- Division Tests ---");
        perform_operation(32'h41200000, 32'h40000000, OP_DIV, "DIV");  // 10.0 / 2.0 = 5.0
        perform_operation(32'h40A00000, 32'h40A00000, OP_DIV, "DIV");  // 5.0 / 5.0 = 1.0
        perform_operation(32'h40400000, 32'h40000000, OP_DIV, "DIV");  // 3.0 / 2.0 = 1.5
        
        // Test Special Cases
        $display("\n--- Special Cases ---");
        perform_operation(32'h7F800000, 32'h40000000, OP_ADD, "ADD");  // Inf + 2.0 = Inf
        perform_operation(32'h40000000, 32'h00000000, OP_DIV, "DIV");  // 2.0 / 0.0 = Inf (invalid)
        perform_operation(32'h00000000, 32'h00000000, OP_DIV, "DIV");  // 0.0 / 0.0 = NaN (invalid)
        perform_operation(32'h7FC00000, 32'h40000000, OP_ADD, "ADD");  // NaN + 2.0 = NaN (invalid)
        
        // Test Negative Numbers
        $display("\n--- Negative Number Tests ---");
        perform_operation(32'hC0000000, 32'h40000000, OP_ADD, "ADD");  // -2.0 + 2.0 = 0.0
        perform_operation(32'hC0400000, 32'hC0000000, OP_ADD, "ADD");  // -3.0 + (-2.0) = -5.0
        perform_operation(32'hC0000000, 32'h40400000, OP_MUL, "MUL");  // -2.0 * 3.0 = -6.0
        
        #100;
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Monitor changes
    initial begin
        $monitor("Time=%0t ready=%b result=%h overflow=%b underflow=%b invalid=%b",
                 $time, ready, result, overflow, underflow, invalid);
    end

endmodule
