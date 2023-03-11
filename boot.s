.set ALIGN,     1<<0              /* align loaded modules on page boundaries */
.set MEMINFO,   1<<1              /* provide memory map */
.set FLAGS,     ALIGN | MEMINFO   /* multiboot flags */
.set MAGIC,     0x1BADB002        /* lets bootload find the header */
.set CHECKSUM,  -(MAGIC + FLAGS)  /* header checksum for multiboot */

.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/* allocate 16384 bytes for a stack to be set in kernel */
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

/* bootloader jumps to this position once the kernel has been loaded. */
.section .text
.global _start
.type _start @function

_start:
  mov $stach_top, %esp          /* point esp to the top of the stack */
  call kernel_main              /* enter the high level kernel */

  cli                           /* disable interrupts (clear interrupt enable in eflags). */
1:
  hlt                           /* wait or interrupt. Since they are disabled, locks the computer */
  jmp 1b                        /* jmp to hlt instruction if it wakes up due to non-maskable interrupt or system managment mode. */

.size _start, . - _start        /* for debugging or call tracing */
