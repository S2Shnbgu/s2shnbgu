// IEEE 754 Single Precision Floating Point Division Module
// Format: Sign(1) | Exponent(8) | Mantissa(23)

module fpu_divide (
    input  wire [31:0] a,           // Dividend
    input  wire [31:0] b,           // Divisor
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
    reg [47:0] mant_dividend;
    reg [23:0] mant_divisor;
    reg [47:0] mant_quotient;
    reg [9:0]  exp_diff;
    reg        sign_result;
    reg [7:0]  exp_result;
    reg [22:0] mant_result;
    integer    i;
    
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
        // 0 / 0 is invalid
        else if ((exp_a == 0 && mant_a == 0) && (exp_b == 0 && mant_b == 0)) begin
            invalid = 1'b1;
            result = 32'h7FC00000;  // Return NaN
        end
        // Infinity / Infinity is invalid
        else if (exp_a == 8'hFF && exp_b == 8'hFF) begin
            invalid = 1'b1;
            result = 32'h7FC00000;  // Return NaN
        end
        // Dividend is infinity
        else if (exp_a == 8'hFF) begin
            result = {sign_result, 8'hFF, 23'b0};  // Return signed infinity
        end
        // Divisor is infinity
        else if (exp_b == 8'hFF) begin
            result = {sign_result, 8'b0, 23'b0};  // Return signed zero
        end
        // Division by zero
        else if (exp_b == 0 && mant_b == 0) begin
            invalid = 1'b1;
            result = {sign_result, 8'hFF, 23'b0};  // Return signed infinity (div by 0)
        end
        // Dividend is zero
        else if (exp_a == 0 && mant_a == 0) begin
            result = {sign_result, 8'b0, 23'b0};  // Return signed zero
        end
        // Normal operation
        else begin
            // Add implicit leading 1 for normalized numbers
            mant_dividend = (exp_a != 0) ? {1'b1, mant_a, 24'b0} : {1'b0, mant_a, 24'b0};
            mant_divisor = (exp_b != 0) ? {1'b1, mant_b} : {1'b0, mant_b};
            
            // Perform division using shift and subtract algorithm
            mant_quotient = 0;
            for (i = 47; i >= 0; i = i - 1) begin
                if (mant_dividend >= ({mant_divisor, 24'b0} >> (47 - i))) begin
                    mant_dividend = mant_dividend - ({mant_divisor, 24'b0} >> (47 - i));
                    mant_quotient[i] = 1'b1;
                end
            end
            
            // Calculate exponent (add bias: 127)
            if (exp_a == 0 || exp_b == 0) begin
                // Denormalized handling
                exp_diff = exp_a + 127;
                if (exp_b > 0)
                    exp_diff = exp_diff - exp_b;
            end else begin
                exp_diff = exp_a - exp_b + 127;
            end
            
            // Normalize result
            if (mant_quotient[47]) begin
                // Already normalized
                mant_result = mant_quotient[46:24];
            end else if (mant_quotient[46]) begin
                // Shift left by 1
                mant_result = mant_quotient[45:23];
                exp_diff = exp_diff - 1;
            end else begin
                // Find first 1 bit and normalize
                mant_result = mant_quotient[44:22];
                exp_diff = exp_diff - 2;
            end
            
            // Check for exponent overflow/underflow
            if (exp_diff >= 10'd255) begin
                overflow = 1'b1;
                result = {sign_result, 8'hFF, 23'b0};  // Return signed infinity
            end else if (exp_diff <= 0) begin
                underflow = 1'b1;
                result = {sign_result, 8'b0, 23'b0};  // Return signed zero
            end else begin
                exp_result = exp_diff[7:0];
                result = {sign_result, exp_result, mant_result};
            end
        end
    end

endmodule
