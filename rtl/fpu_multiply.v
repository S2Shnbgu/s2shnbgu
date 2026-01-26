// IEEE 754 Single Precision Floating Point Multiplication Module
// Format: Sign(1) | Exponent(8) | Mantissa(23)

module fpu_multiply (
    input  wire [31:0] a,           // First operand
    input  wire [31:0] b,           // Second operand
    output reg  [31:0] result,      // Result
    output reg         overflow,    // Overflow flag
    output reg         underflow,   // Underflow flag
    output reg         invalid      // Invalid operation flag
);

    // Extract fields from operands
    wire        sign_a, sign_b;
    wire [7:0]  exp_a, exp_b;
    wire [22:0] mant_a, mant_b;
    
    assign sign_a = a[31];
    assign exp_a  = a[30:23];
    assign mant_a = a[22:0];
    
    assign sign_b = b[31];
    assign exp_b  = b[30:23];
    assign mant_b = b[22:0];
    
    // Internal variables
    reg [47:0] mant_product;
    reg [23:0] mant_a_full, mant_b_full;
    reg [9:0]  exp_sum;
    reg        sign_result;
    reg [7:0]  exp_result;
    reg [22:0] mant_result;
    
    always @(*) begin
        // Initialize flags
        overflow  = 1'b0;
        underflow = 1'b0;
        invalid   = 1'b0;
        
        // Calculate result sign
        sign_result = sign_a ^ sign_b;
        
        // Check for special cases
        // NaN detection
        if ((exp_a == 8'hFF && mant_a != 0) || (exp_b == 8'hFF && mant_b != 0)) begin
            invalid = 1'b1;
            result = 32'h7FC00000;  // Return NaN
        end
        // Infinity * 0 is invalid
        else if ((exp_a == 8'hFF && (exp_b == 0 && mant_b == 0)) ||
                 (exp_b == 8'hFF && (exp_a == 0 && mant_a == 0))) begin
            invalid = 1'b1;
            result = 32'h7FC00000;  // Return NaN
        end
        // Infinity multiplication
        else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
            result = {sign_result, 8'hFF, 23'b0};  // Return signed infinity
        end
        // Zero multiplication
        else if ((exp_a == 0 && mant_a == 0) || (exp_b == 0 && mant_b == 0)) begin
            result = {sign_result, 8'b0, 23'b0};  // Return signed zero
        end
        // Normal operation
        else begin
            // Add implicit leading 1 for normalized numbers
            mant_a_full = (exp_a != 0) ? {1'b1, mant_a} : {1'b0, mant_a};
            mant_b_full = (exp_b != 0) ? {1'b1, mant_b} : {1'b0, mant_b};
            
            // Multiply mantissas
            mant_product = mant_a_full * mant_b_full;
            
            // Calculate exponent (subtract bias once: 127)
            // Add exponents and subtract one bias (127)
            if (exp_a == 0 || exp_b == 0) begin
                // Denormalized handling
                exp_sum = exp_a + exp_b;
            end else begin
                exp_sum = exp_a + exp_b - 127;
            end
            
            // Normalize result
            if (mant_product[47]) begin
                // Mantissa overflow, shift right
                mant_result = mant_product[46:24];
                exp_sum = exp_sum + 1;
            end else if (mant_product[46]) begin
                mant_result = mant_product[45:23];
            end else begin
                // Need to shift left to normalize
                mant_result = mant_product[44:22];
                exp_sum = exp_sum - 1;
            end
            
            // Check for exponent overflow/underflow
            if (exp_sum >= 10'd255) begin
                overflow = 1'b1;
                result = {sign_result, 8'hFF, 23'b0};  // Return signed infinity
            end else if (exp_sum <= 0) begin
                underflow = 1'b1;
                result = {sign_result, 8'b0, 23'b0};  // Return signed zero
            end else begin
                exp_result = exp_sum[7:0];
                result = {sign_result, exp_result, mant_result};
            end
        end
    end

endmodule
