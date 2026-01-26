# Makefile for IEEE 754 Floating Point Unit

# Verilog compiler
VERILOG = iverilog
VVP = vvp

# Directories
RTL_DIR = rtl
TB_DIR = testbench

# Source files
FPU_SOURCES = $(RTL_DIR)/fpu_add_sub.v $(RTL_DIR)/fpu_multiply.v $(RTL_DIR)/fpu_divide.v $(RTL_DIR)/fpu.v

# Simulation targets
FPU_SIM = fpu_sim
ADD_SUB_SIM = add_sub_sim

.PHONY: all clean test test_fpu test_add_sub help

# Default target
all: test_fpu

help:
	@echo "Available targets:"
	@echo "  make test          - Run all tests"
	@echo "  make test_fpu      - Test complete FPU"
	@echo "  make test_add_sub  - Test addition/subtraction module"
	@echo "  make clean         - Remove simulation files"
	@echo "  make help          - Show this help message"

# Compile and test complete FPU
test_fpu: $(FPU_SIM)
	@echo "Running FPU simulation..."
	$(VVP) $(FPU_SIM)

$(FPU_SIM): $(FPU_SOURCES) $(TB_DIR)/fpu_tb.v
	@echo "Compiling FPU design and testbench..."
	$(VERILOG) -o $(FPU_SIM) $(FPU_SOURCES) $(TB_DIR)/fpu_tb.v

# Compile and test addition/subtraction module
test_add_sub: $(ADD_SUB_SIM)
	@echo "Running addition/subtraction module simulation..."
	$(VVP) $(ADD_SUB_SIM)

$(ADD_SUB_SIM): $(RTL_DIR)/fpu_add_sub.v $(TB_DIR)/fpu_add_sub_tb.v
	@echo "Compiling addition/subtraction module and testbench..."
	$(VERILOG) -o $(ADD_SUB_SIM) $(RTL_DIR)/fpu_add_sub.v $(TB_DIR)/fpu_add_sub_tb.v

# Run all tests
test: test_add_sub test_fpu
	@echo "All tests completed!"

# Clean simulation files
clean:
	@echo "Cleaning simulation files..."
	rm -f $(FPU_SIM) $(ADD_SUB_SIM)
	rm -f *.vcd *.out
	@echo "Clean complete!"
