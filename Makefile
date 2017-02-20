NVCC = /usr/local/cuda/bin/nvcc

NVCC_FLAGS = -I/usr/local/cuda/include -lineinfo

# make emu=1 compiles the CUDA kernels for emulation
ifeq ($(emu),1)
	NVCC_FLAGS += -deviceemu
endif

all: assign2

assign2: assign2.cu
	$(NVCC) $(NVCC_FLAGS) assign2.cu -o assign2 -lcuda

clean:
	rm -f *.o *~ assign2

	
