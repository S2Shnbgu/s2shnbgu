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
    reg [24:0] mant_a_full, mant_b_full;  // With implicit leading 1 + extra bit
    reg [26:0] mant_a_aligned, mant_b_aligned;  // Aligned mantissas with guard bits
    reg [26:0] mant_result_temp;
    reg        sign_result;
    reg [8:0]  exp_result;  // 9 bits to detect overflow/underflow
    reg [22:0] mant_result;
    reg [4:0]  leading_zeros;
    
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
            mant_a_full = (exp_a != 0) ? {2'b01, mant_a} : {2'b00, mant_a};
            mant_b_full = (exp_b != 0) ? {2'b01, mant_b} : {2'b00, mant_b};
            
            // Align mantissas - shift smaller one to right
            if (exp_a >= exp_b) begin
                larger_exp = exp_a;
                exp_diff = exp_a - exp_b;
                mant_a_aligned = {mant_a_full, 2'b00};
                if (exp_diff < 27)
                    mant_b_aligned = {mant_b_full, 2'b00} >> exp_diff;
                else
                    mant_b_aligned = 27'b0;
            end else begin
                larger_exp = exp_b;
                exp_diff = exp_b - exp_a;
                mant_b_aligned = {mant_b_full, 2'b00};
                if (exp_diff < 27)
                    mant_a_aligned = {mant_a_full, 2'b00} >> exp_diff;
                else
                    mant_a_aligned = 27'b0;
            end
            
            // Perform addition or subtraction
            if ((sign_a ^ sub) == sign_b) begin
                // Same effective signs - add
                mant_result_temp = mant_a_aligned + mant_b_aligned;
                sign_result = sign_a;
            end else begin
                // Different effective signs - subtract
                if (mant_a_aligned >= mant_b_aligned) begin
                    mant_result_temp = mant_a_aligned - mant_b_aligned;
                    sign_result = sign_a;
                end else begin
                    mant_result_temp = mant_b_aligned - mant_a_aligned;
                    sign_result = sign_b ^ sub;
                end
            end
            
            exp_result = {1'b0, larger_exp};
            
            // Normalize the result
            if (mant_result_temp == 0) begin
                // Result is zero
                result = 32'b0;
            end
            else if (mant_result_temp[26]) begin
                // Carry out - shift right
                mant_result = mant_result_temp[25:3];
                exp_result = exp_result + 1;
                if (exp_result >= 9'd255) begin
                    overflow = 1'b1;
                    result = {sign_result, 8'hFF, 23'b0};
                end else begin
                    result = {sign_result, exp_result[7:0], mant_result};
                end
            end
            else begin
                // Count leading zeros and normalize
                leading_zeros = 0;
                if (mant_result_temp[25] == 1'b1) begin
                    leading_zeros = 0;
                end else if (mant_result_temp[24] == 1'b1) begin
                    leading_zeros = 1;
                end else if (mant_result_temp[23] == 1'b1) begin
                    leading_zeros = 2;
                end else if (mant_result_temp[22] == 1'b1) begin
                    leading_zeros = 3;
                end else if (mant_result_temp[21] == 1'b1) begin
                    leading_zeros = 4;
                end else if (mant_result_temp[20] == 1'b1) begin
                    leading_zeros = 5;
                end else if (mant_result_temp[19] == 1'b1) begin
                    leading_zeros = 6;
                end else if (mant_result_temp[18] == 1'b1) begin
                    leading_zeros = 7;
                end else if (mant_result_temp[17] == 1'b1) begin
                    leading_zeros = 8;
                end else if (mant_result_temp[16] == 1'b1) begin
                    leading_zeros = 9;
                end else if (mant_result_temp[15] == 1'b1) begin
                    leading_zeros = 10;
                end else if (mant_result_temp[14] == 1'b1) begin
                    leading_zeros = 11;
                end else if (mant_result_temp[13] == 1'b1) begin
                    leading_zeros = 12;
                end else if (mant_result_temp[12] == 1'b1) begin
                    leading_zeros = 13;
                end else if (mant_result_temp[11] == 1'b1) begin
                    leading_zeros = 14;
                end else if (mant_result_temp[10] == 1'b1) begin
                    leading_zeros = 15;
                end else if (mant_result_temp[9] == 1'b1) begin
                    leading_zeros = 16;
                end else if (mant_result_temp[8] == 1'b1) begin
                    leading_zeros = 17;
                end else if (mant_result_temp[7] == 1'b1) begin
                    leading_zeros = 18;
                end else if (mant_result_temp[6] == 1'b1) begin
                    leading_zeros = 19;
                end else if (mant_result_temp[5] == 1'b1) begin
                    leading_zeros = 20;
                end else if (mant_result_temp[4] == 1'b1) begin
                    leading_zeros = 21;
                end else if (mant_result_temp[3] == 1'b1) begin
                    leading_zeros = 22;
                end else if (mant_result_temp[2] == 1'b1) begin
                    leading_zeros = 23;
                end else begin
                    leading_zeros = 24;
                end
                
                // Shift left to normalize and adjust exponent
                if (leading_zeros > exp_result) begin
                    // Would underflow
                    underflow = 1'b1;
                    result = {sign_result, 8'b0, 23'b0};
                end else begin
                    exp_result = exp_result - leading_zeros;
                    mant_result = (mant_result_temp << leading_zeros) >> 3;
                    mant_result = mant_result[22:0];
                    result = {sign_result, exp_result[7:0], mant_result};
                end
            end
        end
    end

endmodule
