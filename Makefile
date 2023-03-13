# snowcra5h@icloud.com

AS=i686-elf-as
CC=i686-elf-gcc

CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra

DEPS=
CFILES=kernel.c
COBJ=kernel.o

AFILES=boot.s
AOBJ=boot.o

OBJ=$(COBJ) $(AOBJ)

LINK=linker.ld
LFLAGS=-ffreestanding -O2 -nostdlib
PROG=ratthing.prg

define colorecho
	@tput setaf $2
	@echo $1
	@tput sgr0
endef

$(AOBJ): $(AFILES)
	$(call colorecho, " + Building $@", 6)
	$(AS) -o $@ $<

$(COBJ): $(CFILES) $(DEPS)
	$(call colorecho," + Building $@", 6)
	$(CC) -c -o $@ $< $(CFLAGS)

all: $(OBJ)
	$(call colorecho," + Linking $^", 6)
	$(CC) -T $(LINK) -o $(PROG) $(LFLAGS) $^ -lgcc
	$(call colorecho,"\nTo run: qemu-system-i386 -kernel ratthing.prg\n", 2)
clean:
	$(call colorecho," + Cleaning", 1)
	rm -f $(PROG) *.o
