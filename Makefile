AS = i686-elf-as

source = boot.s
objects = boot.o

all: $(objects)
	
mov.o: mov.s
	$(AS) $(source) -o $(objects)

clean:
	rm -rf $(objects)
