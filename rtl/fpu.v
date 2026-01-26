// IEEE 754 Single Precision Floating Point Unit (FPU)
// Top-level module integrating all FPU operations
// Format: Sign(1) | Exponent(8) | Mantissa(23)

module fpu (
    input  wire        clk,         // Clock signal
    input  wire        rst,         // Reset signal
    input  wire [31:0] operand_a,   // First operand
    input  wire [31:0] operand_b,   // Second operand
    input  wire [1:0]  operation,   // Operation select: 00=ADD, 01=SUB, 10=MUL, 11=DIV
    input  wire        start,       // Start operation
    output reg  [31:0] result,      // Result
    output reg         ready,       // Operation complete
    output reg         overflow,    // Overflow exception
    output reg         underflow,   // Underflow exception
    output reg         invalid      // Invalid operation exception
);

    // Operation codes
    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_MUL = 2'b10;
    localparam OP_DIV = 2'b11;
    
    // Internal signals for each operation module
    wire [31:0] add_result, mul_result, div_result;
    wire        add_overflow, add_underflow, add_invalid;
    wire        mul_overflow, mul_underflow, mul_invalid;
    wire        div_overflow, div_underflow, div_invalid;
    
    // Instantiate addition/subtraction module
    fpu_add_sub add_sub_unit (
        .a(operand_a),
        .b(operand_b),
        .sub(operation[0]),     // 0 for add, 1 for sub
        .result(add_result),
        .overflow(add_overflow),
        .underflow(add_underflow),
        .invalid(add_invalid)
    );
    
    // Instantiate multiplication module
    fpu_multiply mul_unit (
        .a(operand_a),
        .b(operand_b),
        .result(mul_result),
        .overflow(mul_overflow),
        .underflow(mul_underflow),
        .invalid(mul_invalid)
    );
    
    // Instantiate division module
    fpu_divide div_unit (
        .a(operand_a),
        .b(operand_b),
        .result(div_result),
        .overflow(div_overflow),
        .underflow(div_underflow),
        .invalid(div_invalid)
    );
    
    // State machine for operation control
    reg [1:0] state;
    localparam IDLE      = 2'b00;
    localparam COMPUTING = 2'b01;
    localparam DONE      = 2'b10;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            result    <= 32'b0;
            ready     <= 1'b1;
            overflow  <= 1'b0;
            underflow <= 1'b0;
            invalid   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= COMPUTING;
                        ready <= 1'b0;
                    end else begin
                        ready <= 1'b1;
                    end
                end
                
                COMPUTING: begin
                    // Select result based on operation
                    case (operation)
                        OP_ADD, OP_SUB: begin
                            result    <= add_result;
                            overflow  <= add_overflow;
                            underflow <= add_underflow;
                            invalid   <= add_invalid;
                        end
                        OP_MUL: begin
                            result    <= mul_result;
                            overflow  <= mul_overflow;
                            underflow <= mul_underflow;
                            invalid   <= mul_invalid;
                        end
                        OP_DIV: begin
                            result    <= div_result;
                            overflow  <= div_overflow;
                            underflow <= div_underflow;
                            invalid   <= div_invalid;
                        end
                        default: begin
                            result    <= 32'b0;
                            overflow  <= 1'b0;
                            underflow <= 1'b0;
                            invalid   <= 1'b1;
                        end
                    endcase
                    state <= DONE;
                end
                
                DONE: begin
                    ready <= 1'b1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
