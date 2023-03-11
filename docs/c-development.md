# C Development wiki

## Hosted Environment
Note: There is no C standard library. We are using a freestanding environment. However, some header files remain.
- `<stdbool.h>` bool datatype
- `<stddef.h>` size_t and NULL
- `<stdint.h>` intx_t and uintx_t where x is an element of S such that S={8, 16, 32}
- `<float.h>`
- `<iso646.h>`
- `<limits.h>`
- `<stdarg.h>`

## Writing a Kernel in C
The VGA text mode buffer is located at `0xB8000` as an output device. It is a driver that will remember the location of the next character in the buffer, and has a primitive for adding a new character. There is no support for escape characters, there is also no support for scrolling.

VGA text mode and the BIOS is depreceated on newer machines. The UEFI only supports pixel buffers. We must do the following.
1. Ask GRUB to set up a framebuffer using multiboot flags or call [VESA VBE](https://wiki.osdev.org/Vesa)
2. Draw each glyph since we have to use a frame buffer.
3. [PC Screen Fonts](https://wiki.osdev.org/PC_Screen_Font).
