// IEEE 754 Single Precision Floating Point Addition/Subtraction Module
// Format: Sign(1) | Exponent(8) | Mantissa(23)

module fpu_add_sub (
    input  wire [31:0] a,           // First operand
    input  wire [31:0] b,           // Second operand
    input  wire        sub,         // 0 for addition, 1 for subtraction
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
    reg [7:0]  exp_diff;
    reg [7:0]  larger_exp;
    reg [23:0] mant_a_full, mant_b_full;  // With implicit leading 1
    reg [24:0] mant_a_shifted, mant_b_shifted;
    reg [24:0] mant_sum;
    reg        sign_result;
    reg [7:0]  exp_result;
    reg [22:0] mant_result;
    reg [4:0]  norm_shift;
    integer    i;
    
    always @(*) begin
        // Initialize flags
        overflow  = 1'b0;
        underflow = 1'b0;
        invalid   = 1'b0;
        
        // Check for special cases
        // NaN detection
        if ((exp_a == 8'hFF && mant_a != 0) || (exp_b == 8'hFF && mant_b != 0)) begin
            invalid = 1'b1;
            result = 32'h7FC00000;  // Return NaN
        end
        // Infinity detection
        else if (exp_a == 8'hFF || exp_b == 8'hFF) begin
            if (exp_a == 8'hFF && exp_b == 8'hFF) begin
                if ((sign_a ^ sub) == sign_b) begin
                    result = a;  // Same sign infinities
                end else begin
                    invalid = 1'b1;
                    result = 32'h7FC00000;  // Inf - Inf is invalid
                end
            end else if (exp_a == 8'hFF) begin
                result = {sign_a, 8'hFF, 23'b0};
            end else begin
                result = {sign_b ^ sub, 8'hFF, 23'b0};
            end
        end
        // Zero handling
        else if (exp_a == 0 && mant_a == 0) begin
            if (sub)
                result = {~sign_b, exp_b, mant_b};
            else
                result = b;
        end
        else if (exp_b == 0 && mant_b == 0) begin
            result = a;
        end
        // Normal operation
        else begin
            // Add implicit leading 1 for normalized numbers
            mant_a_full = (exp_a != 0) ? {1'b1, mant_a} : {1'b0, mant_a};
            mant_b_full = (exp_b != 0) ? {1'b1, mant_b} : {1'b0, mant_b};
            
            // Determine which exponent is larger
            if (exp_a > exp_b) begin
                larger_exp = exp_a;
                exp_diff = exp_a - exp_b;
                mant_a_shifted = {mant_a_full, 1'b0};
                mant_b_shifted = {mant_b_full, 1'b0} >> exp_diff;
            end else begin
                larger_exp = exp_b;
                exp_diff = exp_b - exp_a;
                mant_a_shifted = {mant_a_full, 1'b0} >> exp_diff;
                mant_b_shifted = {mant_b_full, 1'b0};
            end
            
            // Perform addition or subtraction based on signs
            if ((sign_a ^ sub) == sign_b) begin
                // Same effective sign - add mantissas
                mant_sum = mant_a_shifted + mant_b_shifted;
                sign_result = sign_a;
            end else begin
                // Different effective signs - subtract mantissas
                if (mant_a_shifted >= mant_b_shifted) begin
                    mant_sum = mant_a_shifted - mant_b_shifted;
                    sign_result = sign_a;
                end else begin
                    mant_sum = mant_b_shifted - mant_a_shifted;
                    sign_result = sign_b ^ sub;
                end
            end
            
            exp_result = larger_exp;
            
            // Normalize result
            if (mant_sum == 0) begin
                // Result is zero
                result = 32'b0;
            end else if (mant_sum[24]) begin
                // Overflow in mantissa, shift right
                mant_result = mant_sum[23:1];
                exp_result = exp_result + 1;
                
                // Check for exponent overflow
                if (exp_result >= 8'hFF) begin
                    overflow = 1'b1;
                    result = {sign_result, 8'hFF, 23'b0};  // Return infinity
                end else begin
                    result = {sign_result, exp_result, mant_result};
                end
            end else begin
                // Need to normalize by shifting left
                norm_shift = 0;
                for (i = 23; i >= 0; i = i - 1) begin
                    if (mant_sum[i] && norm_shift == 0) begin
                        norm_shift = 23 - i;
                    end
                end
                
                if (norm_shift >= exp_result) begin
                    // Would result in denormalized number or underflow
                    if (exp_result == 0) begin
                        underflow = 1'b1;
                        result = {sign_result, 8'b0, 23'b0};  // Return zero
                    end else begin
                        mant_result = (mant_sum << (exp_result - 1)) & 24'h7FFFFF;
                        result = {sign_result, 8'b0, mant_result};  // Denormalized
                        underflow = 1'b1;
                    end
                end else begin
                    mant_result = (mant_sum << norm_shift) & 24'h7FFFFF;
                    exp_result = exp_result - norm_shift;
                    result = {sign_result, exp_result, mant_result};
                end
            end
        end
    end

endmodule
