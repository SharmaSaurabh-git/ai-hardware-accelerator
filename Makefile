# Makefile for systolic array simulation
# Requires Verilator (sudo apt-get install verilator) or similar

VERILATOR = verilator
VERILATOR_FLAGS = -Wall --cc --exe -O3
TOP_MODULE = tb_systolic_array
SOURCES = rtl/systolic_array.sv rtl/pe.sv rtl/fifo_sync.sv tb/tb_systolic_array.sv
EXE = obj_dir/V$(TOP_MODULE)

all: sim

sim: $(EXE)
	@echo "Running simulation..."
	@./$(EXE)

$(EXE): $(SOURCES)
	@echo "Compiling with Verilator..."
	@mkdir -p obj_dir
	$(VERILATOR) $(VERILATOR_FLAGS) $(SOURCES) --top-module $(TOP_MODULE)
	@make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)

clean:
	@rm -rf obj_dir
	@rm -f systolic_array.vcd

.PHONY: all sim clean
