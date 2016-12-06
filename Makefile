# Change this path if the SDK was installed in a non-standard location
OPENCL_HEADERS = "/opt/AMDAPPSDK-3.0/include"
# By default libOpenCL.so is searched in default system locations, this path
# lets you adds one more directory to the search path.
LIBOPENCL = "/opt/amdgpu-pro/lib/x86_64-linux-gnu"

CC = clang
CFLAGS = -fsanitize=memory -fsanitize-memory-track-origins -fPIE -pie -fno-omit-frame-pointer -g -O2 -pedantic -Wextra -Wall -Wno-deprecated-declarations -Wno-overlength-strings
LDFLAGS = -rdynamic -L${LIBOPENCL}
LDLIBS = -lOpenCL -lrt
SRC = main.c blake.c sha256.c
#OBJ = main.o blake.o sha256.o
INCLUDES = blake.h param.h _kernel.h sha256.h

all : sa-solver

sa-solver : ${SRC} ${INCLUDES}
	${CC} -o sa-solver ${SRC} ${LDFLAGS} ${LDLIBS}

${OBJ} : ${INCLUDES}

_kernel.h: input.cl param.h
	cpp $< ocl.code
	echo -ne "\x00" >> ocl.code
	xxd -i ocl.code _kernel.h

test : sa-solver
	@echo Testing...
	@if res=`./sa-solver --nonces 100 -v -v 2>&1 | grep Soln: | \
	    diff -u testing/sols-100 -`; then \
	    echo "Test: success"; \
	else \
	    echo "$$res\nTest: FAILED" | cut -c 1-75 >&2; \
	fi
#	When compiling with NR_ROWS_LOG != 20, the solutions it finds are
#	different: testing/sols-100

clean :
	rm -f sa-solver _kernel.h *.o _temp_* ocl.code

re : clean all
