# IEEE 754 Floating Point Unit (FPU) - Technical Documentation

## Overview

This repository contains a complete implementation of an IEEE 754 Single Precision (32-bit) Floating Point Unit (FPU) in Verilog. The FPU supports the four basic arithmetic operations: addition, subtraction, multiplication, and division, with full exception handling.

## IEEE 754 Single Precision Format

The 32-bit floating-point format consists of:
- **Sign bit (1 bit)**: Bit 31
- **Exponent (8 bits)**: Bits 30-23 (biased by 127)
- **Mantissa/Fraction (23 bits)**: Bits 22-0 (with implicit leading 1)

```
| Sign (1) | Exponent (8) | Mantissa (23) |
|----------|--------------|---------------|
|    31    |   30 ... 23  |   22 ... 0    |
```

### Value Representation
- **Normalized numbers**: (-1)^sign × 1.mantissa × 2^(exponent-127)
- **Zero**: exponent = 0, mantissa = 0
- **Denormalized**: exponent = 0, mantissa ≠ 0
- **Infinity**: exponent = 255, mantissa = 0
- **NaN**: exponent = 255, mantissa ≠ 0

## Architecture

### Module Hierarchy

```
fpu (Top-level)
├── fpu_add_sub (Addition/Subtraction)
├── fpu_multiply (Multiplication)
└── fpu_divide (Division)
```

### Top-Level FPU Module (`fpu.v`)

The main FPU module integrates all arithmetic operations and provides a unified interface.

#### Ports

**Inputs:**
- `clk` - Clock signal
- `rst` - Reset signal (active high)
- `operand_a[31:0]` - First operand (IEEE 754 format)
- `operand_b[31:0]` - Second operand (IEEE 754 format)
- `operation[1:0]` - Operation select
  - `2'b00`: Addition
  - `2'b01`: Subtraction
  - `2'b10`: Multiplication
  - `2'b11`: Division
- `start` - Start operation signal

**Outputs:**
- `result[31:0]` - Result (IEEE 754 format)
- `ready` - Operation complete flag
- `overflow` - Overflow exception flag
- `underflow` - Underflow exception flag
- `invalid` - Invalid operation exception flag

#### State Machine

The FPU operates using a simple state machine:
1. **IDLE**: Waiting for start signal
2. **COMPUTING**: Performing the requested operation
3. **DONE**: Operation complete, result available

### Addition/Subtraction Module (`fpu_add_sub.v`)

Implements floating-point addition and subtraction using the following algorithm:

1. **Extract** sign, exponent, and mantissa from both operands
2. **Align** mantissas by adjusting for exponent difference
3. **Add/Subtract** aligned mantissas based on signs
4. **Normalize** result
5. **Handle** special cases (zero, infinity, NaN)

#### Special Cases Handled
- Zero operands
- Infinity ± finite number
- Infinity ± Infinity
- NaN propagation

### Multiplication Module (`fpu_multiply.v`)

Implements floating-point multiplication:

1. **Calculate** result sign (XOR of input signs)
2. **Add** exponents and subtract bias (127)
3. **Multiply** mantissas (24-bit × 24-bit = 48-bit)
4. **Normalize** result
5. **Check** for overflow/underflow

#### Special Cases Handled
- Zero × any number = Zero
- Infinity × Infinity = Infinity
- Infinity × 0 = NaN (invalid)
- NaN propagation

### Division Module (`fpu_divide.v`)

Implements floating-point division using shift-and-subtract algorithm:

1. **Calculate** result sign (XOR of input signs)
2. **Subtract** exponents and add bias (127)
3. **Divide** mantissas using iterative algorithm
4. **Normalize** result
5. **Check** for overflow/underflow

#### Special Cases Handled
- Any number ÷ 0 = Infinity (invalid for 0÷0)
- 0 ÷ 0 = NaN (invalid)
- Infinity ÷ Infinity = NaN (invalid)
- Infinity ÷ finite = Infinity
- Finite ÷ Infinity = 0
- NaN propagation

## Exception Handling

### Overflow
Occurs when the result magnitude is too large to represent:
- Exponent > 254
- Result is set to signed infinity

### Underflow
Occurs when the result magnitude is too small to represent:
- Exponent < 1 for normalized numbers
- Result is set to signed zero or denormalized number

### Invalid Operation
Occurs for mathematically undefined operations:
- 0 ÷ 0
- Infinity - Infinity
- Infinity × 0
- Infinity ÷ Infinity
- Operations involving NaN
- Result is set to NaN (0x7FC00000)

## Test Benches

### Main Test Bench (`testbench/fpu_tb.v`)

Comprehensive test bench that validates:
- Basic arithmetic operations
- Positive and negative numbers
- Special values (zero, infinity, NaN)
- Exception conditions
- Edge cases

### Module-Specific Test Benches

Individual test benches for each arithmetic module:
- `fpu_add_sub_tb.v` - Addition/Subtraction tests

## Usage Example

### Verilog Instantiation

```verilog
wire [31:0] result;
wire ready, overflow, underflow, invalid;

fpu my_fpu (
    .clk(clk),
    .rst(rst),
    .operand_a(32'h40400000),  // 3.0
    .operand_b(32'h40000000),  // 2.0
    .operation(2'b00),          // Addition
    .start(start_signal),
    .result(result),            // 5.0
    .ready(ready),
    .overflow(overflow),
    .underflow(underflow),
    .invalid(invalid)
);
```

### Simulation

To run simulations using Icarus Verilog:

```bash
# Compile the design and testbench
iverilog -o fpu_sim rtl/fpu_add_sub.v rtl/fpu_multiply.v rtl/fpu_divide.v rtl/fpu.v testbench/fpu_tb.v

# Run simulation
vvp fpu_sim

# View waveforms (if using VCD)
gtkwave fpu.vcd
```

## Common IEEE 754 Values (32-bit)

| Value | Hex        | Binary                                  |
|-------|------------|-----------------------------------------|
| 0.0   | 0x00000000 | 0 00000000 00000000000000000000000     |
| 1.0   | 0x3F800000 | 0 01111111 00000000000000000000000     |
| 2.0   | 0x40000000 | 0 10000000 00000000000000000000000     |
| 3.0   | 0x40400000 | 0 10000000 10000000000000000000000     |
| 5.0   | 0x40A00000 | 0 10000001 01000000000000000000000     |
| 10.0  | 0x41200000 | 0 10000010 01000000000000000000000     |
| -1.0  | 0xBF800000 | 1 01111111 00000000000000000000000     |
| +Inf  | 0x7F800000 | 0 11111111 00000000000000000000000     |
| -Inf  | 0xFF800000 | 1 11111111 00000000000000000000000     |
| NaN   | 0x7FC00000 | 0 11111111 10000000000000000000000     |

## Design Considerations

### Timing
- All operations complete in 2 clock cycles (COMPUTING and DONE states)
- Combinational logic for arithmetic operations
- Sequential control logic for state machine

### Area
- Approximately 48-bit multipliers for mantissa operations
- Minimal state storage (2-bit state machine)
- Shared control logic

### Accuracy
- Full IEEE 754 compliance for special values
- Proper rounding is simplified (truncation)
- For production use, consider implementing proper rounding modes

## Future Enhancements

Possible improvements for this design:
1. **Rounding modes**: Implement all IEEE 754 rounding modes
2. **Double precision**: Extend to 64-bit floating-point
3. **Fused operations**: Add FMA (Fused Multiply-Add)
4. **Pipelining**: Pipeline operations for higher throughput
5. **Denormalized numbers**: Better handling of subnormal numbers
6. **Status flags**: Additional IEEE 754 status flags

## References

- IEEE Standard 754-2008 for Floating-Point Arithmetic
- Verilog HDL Synthesis
- Computer Organization and Design (Patterson & Hennessy)

## License

This implementation is provided as-is for educational and research purposes.
