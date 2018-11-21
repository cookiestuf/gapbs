# See LICENSE.txt for license details.

#CXX = ${RISCV}/bin/riscv64-unknown-elf-g++ #run on x86 machines
CXX = ${RISCV}/bin/riscv64-unknown-linux-gnu-g++ #for running on RV64 machines

CXX_FLAGS += -std=c++11 -O3 -Wall -static
PAR_FLAG = -fopenmp

ifneq (,$(findstring icpc,$(CXX)))
	PAR_FLAG = -openmp
endif

ifneq (,$(findstring sunCC,$(CXX)))
	CXX_FLAGS = -std=c++11 -xO3 -m64 -xtarget=native
	PAR_FLAG = -xopenmp
endif

ifneq ($(SERIAL), 1)
	CXX_FLAGS += $(PAR_FLAG)
endif

KERNELS = bc bfs cc pr sssp tc
SUITE = $(KERNELS)

.PHONY: all
all: $(SUITE)

% : src/%.cc src/*.h
	$(CXX) $(CXX_FLAGS) $< -o $@

# Testing
include test/test.mk

# Benchmark Automation
include benchmark/bench.mk


.PHONY: clean
clean:
	rm -f $(SUITE) test/out/*
