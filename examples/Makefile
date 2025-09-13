CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -static

all: fib.bin

fib.elf: fib.c
	$(CC) $(CFLAGS) -o fib.elf fib.c

fib.bin: fib.elf
	$(OBJCOPY) -O binary fib.elf fib.bin

clean:
	rm -f fib.elf fib.bin