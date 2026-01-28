INC_DIR   := src/rtl/include/
SRC_DIR   := src/rtl/
LIB_DIR   := src/rtl/lib/

TEST_NAME := branchy
TEST_DIR  := tests/$(TEST_NAME)
TEST_FILES := $(TEST_DIR)/test.ld $(TEST_DIR)/test.s
TEST_PRE   := $(TEST_DIR)/test.pre

RTL_F := src/rtl.f

INC_FILES := $(wildcard $(INC_DIR)/*.sv)
LIB_FILES := $(wildcard $(LIB_DIR)/*.sv)
SRC_FILES := $(shell cat $(RTL_F))

VERILATOR := verilator -Wall -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM --assert --timing
VL_TRACE_FLAGS := --trace-fst --trace-structs --trace-params

WAVES := waves.fst

VL_DEFINES := +define+SIMULATION=1 +define+ASSERT=1 #+define+DEBUGON=1
VL_WAIVER_OUT := --waiver-output new_waivers.txt

SIM_FLAGS :=

Vtop: verilated
	make -C obj_dir -f Vtop.mk Vtop  -j 8

$(TEST_PRE): $(TEST_FILES)
	make -C $(TEST_DIR) -f Makefile

.PHONY: run
run: Vtop $(TEST_PRE)
	obj_dir/Vtop +load_disasm +preload:$(TEST_DIR)/test.pre +boot_vector:0000000080000000 ${SIM_FLAGS} | tee run.log
	scripts/split_log -f run.log

.PHONY: verilated
verilated: $(SRC_FILES) $(LIB_FILES) 
	$(VERILATOR) $(VL_TRACE_FLAGS) --exe tb_top.cpp --cc -y $(LIB_DIR) -I$(INC_DIR) -I$(SRC_DIR) -f $(RTL_F) $(VL_DEFINES) -o Vtop --top-module top $(VL_WAIVER_OUT)

.PHONY: clean
clean:
	rm -rf obj_dir/
	rm -f waves.fst
	rm -f *.log
	rm -f regress.latest
	rm -rf regress.*

.PHONY: gtkwave
gtkwave:
	gtkwave ${WAVES} ../retch/vroom.gtkw 

.PHONY: surfer
surfer:
	surfer ${WAVES}
