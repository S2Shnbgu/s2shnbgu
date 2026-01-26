# IEEE 754 Floating Point Unit (FPU)

A complete Verilog implementation of a floating-point arithmetic unit compliant with IEEE 754 single-precision (32-bit) standard.

## Features

- ✅ **Addition** - Floating-point addition with proper alignment and normalization
- ✅ **Subtraction** - Floating-point subtraction with sign handling
- ✅ **Multiplication** - Floating-point multiplication with exponent addition
- ✅ **Division** - Floating-point division using shift-and-subtract algorithm
- ✅ **Exception Handling** - Overflow, underflow, and invalid operation detection
- ✅ **Special Values** - Proper handling of zero, infinity, and NaN
- ✅ **Comprehensive Testing** - Test benches for validation

## Project Structure

```
├── rtl/                    # RTL source files
│   ├── fpu.v              # Top-level FPU module
│   ├── fpu_add_sub.v      # Addition/Subtraction module
│   ├── fpu_multiply.v     # Multiplication module
│   └── fpu_divide.v       # Division module
├── testbench/             # Test benches
│   ├── fpu_tb.v           # Main FPU testbench
│   └── fpu_add_sub_tb.v   # Add/Sub testbench
├── docs/                  # Documentation
│   └── FPU_DOCUMENTATION.md
└── README.md
```

## Quick Start

### Prerequisites

Install Icarus Verilog (iverilog):
```bash
# Ubuntu/Debian
sudo apt-get install iverilog

# macOS
brew install icarus-verilog
```

### Simulation with Makefile

```bash
# Run all tests
make test

# Run only FPU tests
make test_fpu

# Run addition/subtraction tests
make test_add_sub

# Clean simulation files
make clean

# Show help
make help
```

### Manual Simulation with Icarus Verilog

```bash
# Compile the design
iverilog -o fpu_sim rtl/fpu_add_sub.v rtl/fpu_multiply.v rtl/fpu_divide.v rtl/fpu.v testbench/fpu_tb.v

# Run simulation
vvp fpu_sim
```

### Using the FPU Module

```verilog
fpu my_fpu (
    .clk(clk),
    .rst(rst),
    .operand_a(32'h40400000),  // 3.0 in IEEE 754
    .operand_b(32'h40000000),  // 2.0 in IEEE 754
    .operation(2'b00),          // 00=ADD, 01=SUB, 10=MUL, 11=DIV
    .start(start),
    .result(result),
    .ready(ready),
    .overflow(overflow),
    .underflow(underflow),
    .invalid(invalid)
);
```

## IEEE 754 Format

32-bit single precision format:
```
| Sign (1 bit) | Exponent (8 bits) | Mantissa (23 bits) |
|--------------|-------------------|--------------------|
|      31      |     30 ... 23     |      22 ... 0      |
```

## Exception Flags

- **Overflow**: Result magnitude too large to represent
- **Underflow**: Result magnitude too small to represent  
- **Invalid**: Mathematically undefined operation (e.g., 0/0, Inf-Inf)

## Documentation

For detailed technical documentation, see [docs/FPU_DOCUMENTATION.md](docs/FPU_DOCUMENTATION.md)

## License

MIT License - See LICENSE file for details
