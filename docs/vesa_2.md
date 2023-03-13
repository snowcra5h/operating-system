# VESA Graphics Modes

The standard VGA modes are acceptable, but soon, you will want a higher resolution, for example, one with more than 256 colors. This means switching to an SVGA mode, which stands for Super-VGA, i.e., better than what was possible with the original VGA cards. Today there are thousands of different and incompatible SVGA cards on the market, but you don't need to write unique code for each because you can use the standard VESA interface.

This software API was designed by the Video Electronics Standards Association and is usually implemented as a loadable TSR utility or as part of the ROM BIOS of your video card. VESA allows you to change graphics modes and display images without knowing the details of each graphics chipset: this is good if you want your program to work on different machines!

If you still need to, you should get a copy of the VESA specification. A lot of material from the official documentation will be repeated here. This tutorial is for beginners rather than a complete technical reference, so you may want to have the specification handy.

All VESA functions are accessed by calling interrupt **0x10** with a value of **0x4F??** in the **AX** register, where **??** represents the specific function you want to execute. They return a zero value in **AH** if the function succeeds or non-zero if an error occurs.

The first step is to ensure a VESA driver is present and collect a copy of the information structure.
```c
   typedef struct VESA_INFO
   {
      unsigned char  VESASignature[4]     __attribute__ ((packed));
      unsigned short VESAVersion          __attribute__ ((packed));
      unsigned long  OEMStringPtr         __attribute__ ((packed));
      unsigned char  Capabilities[4]      __attribute__ ((packed));
      unsigned long  VideoModePtr         __attribute__ ((packed));
      unsigned short TotalMemory          __attribute__ ((packed));
      unsigned short OemSoftwareRev       __attribute__ ((packed));
      unsigned long  OemVendorNamePtr     __attribute__ ((packed));
      unsigned long  OemProductNamePtr    __attribute__ ((packed));
      unsigned long  OemProductRevPtr     __attribute__ ((packed));
      unsigned char  Reserved[222]        __attribute__ ((packed));
      unsigned char  OemData[256]         __attribute__ ((packed));
   } VESA_INFO;
```
The **\_\_attribute\_\_** modifiers are needed to ensure that gcc packs the structure in the standard VESA layout instead of adding bytes between some fields as usual.

Having declared the structure, you can call the **VESA 0x4F00** function to fill it with information about the current driver. As VESA was designed as a real-mode API to be used by 16-bit programs, this data must be transferred using a conventional memory buffer with the **dosmemput()** and **dosmemget()** functions. The following function will copy the **VESA driver information** into a global **VESA_INFO structure**, returning zero if successful or -1 if something went wrong (if no driver is available).
```c
   #include <dpmi.h>
   #include <go32.h>
   #include <sys/farptr.h>

	VESA_INFO vesa_info;

   int get_vesa_info()
   {
      __dpmi_regs r;
      long dosbuf;
      int c;

      /* use the conventional memory transfer buffer */
      dosbuf = __tb & 0xFFFFF;

      /* initialize the buffer to zero */
      for (c=0; c<sizeof(VESA_INFO); c++)
	 _farpokeb(_dos_ds, dosbuf+c, 0);

      dosmemput("VBE2", 4, dosbuf);

      /* call the VESA function */
      r.x.ax = 0x4F00;
      r.x.di = dosbuf & 0xF;
      r.x.es = (dosbuf>>4) & 0xFFFF;
      __dpmi_int(0x10, &r);

      /* quit if there was an error */
      if (r.h.ah)
	 return -1;

      /* copy the resulting data into our structure */
      dosmemget(dosbuf, sizeof(VESA_INFO), &vesa_info);

      /* check that we got the right magic marker value */
      if (strncmp(vesa_info.VESASignature, "VESA", 4) != 0)
	 return -1;

      /* it worked! */
      return 0;
   }
```
After calling the **get_vesa_info()** function, you should examine a few values left in the **vesa_info** structure, notably the **VESAVersion**, **Capabilities**, and **TotalMemory** fields.

Assuming the call was executed successfully, the next step is to find out which mode you want to use and collect another information structure that is specific to that mode. In theory, VESA supports infinite possible resolutions, but most hardware can only handle a few distinctive modes. So far, the most common is 640x800 resolution. Still, most boards can also tolerate 800x600 and 1024x768 sizes, and many can go up to 1280x1024 and 1600x1200, occasionally supporting low-resolution modes like 320x240 and 360x400 and odd sizes like 512x512. There are a few standard modes, such as 640x480 for the 256 color mode, and you will see many tutorials and code that use those fixed values, but it is not a good idea to rely on them because the most recent version of the VESA specification warns that they may change in the future. However, this is not a problem because there is a seamless way to check what modes are available when running, which also has the advantage of allowing your program to support any strange modes that the driver may support in the future or on different hardware, even if you didn't know about it when you wrote it.

Information about a particular mode can be obtained in a similar way to the main VESA information block but using the **0x4F01** function with a different structure:
```c
   typedef struct MODE_INFO
   {
      unsigned short ModeAttributes       __attribute__ ((packed));
      unsigned char  WinAAttributes       __attribute__ ((packed));
      unsigned char  WinBAttributes       __attribute__ ((packed));
      unsigned short WinGranularity       __attribute__ ((packed));
      unsigned short WinSize              __attribute__ ((packed));
      unsigned short WinASegment          __attribute__ ((packed));
      unsigned short WinBSegment          __attribute__ ((packed));
      unsigned long  WinFuncPtr           __attribute__ ((packed));
      unsigned short BytesPerScanLine     __attribute__ ((packed));
      unsigned short XResolution          __attribute__ ((packed));
      unsigned short YResolution          __attribute__ ((packed));
      unsigned char  XCharSize            __attribute__ ((packed));
      unsigned char  YCharSize            __attribute__ ((packed));
      unsigned char  NumberOfPlanes       __attribute__ ((packed));
      unsigned char  BitsPerPixel         __attribute__ ((packed));
      unsigned char  NumberOfBanks        __attribute__ ((packed));
      unsigned char  MemoryModel          __attribute__ ((packed));
      unsigned char  BankSize             __attribute__ ((packed));
      unsigned char  NumberOfImagePages   __attribute__ ((packed));
      unsigned char  Reserved_page        __attribute__ ((packed));
      unsigned char  RedMaskSize          __attribute__ ((packed));
      unsigned char  RedMaskPos           __attribute__ ((packed));
      unsigned char  GreenMaskSize        __attribute__ ((packed));
      unsigned char  GreenMaskPos         __attribute__ ((packed));
      unsigned char  BlueMaskSize         __attribute__ ((packed));
      unsigned char  BlueMaskPos          __attribute__ ((packed));
      unsigned char  ReservedMaskSize     __attribute__ ((packed));
      unsigned char  ReservedMaskPos      __attribute__ ((packed));
      unsigned char  DirectColorModeInfo  __attribute__ ((packed));
      unsigned long  PhysBasePtr          __attribute__ ((packed));
      unsigned long  OffScreenMemOffset   __attribute__ ((packed));
      unsigned short OffScreenMemSize     __attribute__ ((packed));
      unsigned char  Reserved[206]        __attribute__ ((packed));
   } MODE_INFO;


   MODE_INFO mode_info;


   int get_mode_info(int mode)
   {
      __dpmi_regs r;
      long dosbuf;
      int c;

      /* use the conventional memory transfer buffer */
      dosbuf = __tb & 0xFFFFF;

      /* initialize the buffer to zero */
      for (c=0; c<sizeof(MODE_INFO); c++)
	 _farpokeb(_dos_ds, dosbuf+c, 0);

      /* call the VESA function */
      r.x.ax = 0x4F01;
      r.x.di = dosbuf & 0xF;
      r.x.es = (dosbuf>>4) & 0xFFFF;
      r.x.cx = mode;
      __dpmi_int(0x10, &r);

      /* quit if there was an error */
      if (r.h.ah)
	 return -1;

      /* copy the resulting data into our structure */
      dosmemget(dosbuf, sizeof(MODE_INFO), &mode_info);

      /* it worked! */
      return 0;
   }
```

This function is only proper if you know the mode number to pass as the parameter. Still, that information can easily be obtained from the main VESA information block. This contains a list of all the possible modes the driver supports, so you can write a small routine that will cycle through all those modes, collecting information about each one until it finds the one you are looking for. For example:
```c
   int find_vesa_mode(int w, int h)
   {
      int mode_list[256];
      int number_of_modes;
      long mode_ptr;
      int c;

      /* check that the VESA driver exists, and get information about it */
      if (get_vesa_info() != 0)
	 return 0;

      /* convert the mode list pointer from seg:offset to a linear address */
      mode_ptr = ((vesa_info.VideoModePtr & 0xFFFF0000) >> 12) +
		  (vesa_info.VideoModePtr & 0xFFFF);

      number_of_modes = 0;

      /* read the list of available modes */
      while (_farpeekw(_dos_ds, mode_ptr) != 0xFFFF) {
	 mode_list[number_of_modes] = _farpeekw(_dos_ds, mode_ptr);
	 number_of_modes++;
	 mode_ptr += 2;
      }

      /* scan through the list of modes looking for the one that we want */
      for (c=0; c<number_of_modes; c++) {

	 /* get information about this mode */
	 if (get_mode_info(mode_list[c]) != 0)
	    continue;

	 /* check the flags field to make sure this is a color graphics mode,
	  * and that it is supported by the current hardware */
	 if ((mode_info.ModeAttributes & 0x19) != 0x19)
	    continue;

	 /* check that this mode is the right size */
	 if ((mode_info.XResolution != w) || (mode_info.YResolution != h))
	    continue;

	 /* check that there is only one color plane */
	 if (mode_info.NumberOfPlanes != 1)
	    continue;

	 /* check that it is a packed-pixel mode (other values are used for
	  * different memory layouts, eg. 6 for a truecolor resolution) */
	 if (mode_info.MemoryModel != 4)
	    continue;

	 /* check that this is an 8-bit (256 color) mode */
	 if (mode_info.BitsPerPixel != 8)
	    continue;

	 /* if it passed all those checks, this must be the mode we want! */
	 return mode_list[c];
      }

      /* oh dear, there was no mode matching the one we wanted! */
      return 0; 
   }
```

And finally, you are ready to select the VESA graphics mode and start drawing things on the screen! This is done by calling the **0x4F02** function with the mode number in the BX register:
```c
   int set_vesa_mode(int w, int h)
   {
      __dpmi_regs r;
      int mode_number;

      /* find the number for this mode */
      mode_number = find_vesa_mode(w, h);
      if (!mode_number)
	 return -1;

      /* call the VESA mode set function */
      r.x.ax = 0x4F02;
      r.x.bx = mode_number;
      __dpmi_int(0x10, &r);
      if (r.h.ah)
	 return -1;

      /* it worked! */
      return 0;
   }

```

The SVGA video memory is located at a physical address **0xA0000**, just like in **13h** mode, but there's a slight problem there's not enough room to fit everything in there! The original DOS memory mapping only includes space for 64k of video memory between **0xA0000** and **0xB0000**, which is fine for a **320x200** resolution, but not nearly enough for what a **640x480** display requires (which takes up to 300k of framebuffer space and at higher resolutions requires even more). The hardware designers solved this problem using a memory-by-bank architecture, where the **64k** region of VGA memory is used as a sliding window over the video memory inside your card. To access an arbitrary location on the SVGA screen, you must first call the **VESA 0x4F05** function to tell it which bank you want to use and then write to the memory location of that bank. You can choose the bank with the following function:
```c
   void set_vesa_bank(int bank_number)
   {
      __dpmi_regs r;

      r.x.ax = 0x4F05;
      r.x.bx = 0;
      r.x.dx = bank_number;
      __dpmi_int(0x10, &r);
   }
```

Using this, a simple **putpixel** function can be implemented as:
```c
   void putpixel_vesa_640x480(int x, int y, int color)
   {
      int address = y*640+x;
      int bank_size = mode_info.WinGranularity*1024;
      int bank_number = address/bank_size;
      int bank_offset = address%bank_size;

      set_vesa_bank(bank_number);

      _farpokeb(_dos_ds, 0xA0000+bank_offset, color);
   }
```
Many VESA tutorials and a few production programs assume that SVGA memory banks will always be 64k in size. This is true on about 95% of cards, but there is some hardware out there with bank sizes of 4k or 16k, so the correct approach is to read the bank size from the **WinGranularity** field of the mode information structure, as demonstrated above.

The **bank-swapping** function is slow! This simplistic **putpixel** routine must be more efficient and valuable in real life. It can be improved by making the **set_vesa_bank()** function only change banks if the new value is different from the current one, and you should optimize your more complex drawing functions to use as few bank changes as possible.

Since bank switching is so slow and clumsy, it is usually more helpful to do all the drawing in a framebuffer array in regular memory and copy it around the VESA window in one step once the image is complete. This can be done using the function on the following lines:
```c
   void copy_to_vesa_screen(char *memory_buffer, int screen_size)
   {
      int bank_size = mode_info.WinSize*1024;
      int bank_granularity = mode_info.WinGranularity*1024;
      int bank_number = 0;
      int todo = screen_size;
      int copy_size;

      while (todo > 0) {
	 /* select the appropriate bank */
	 set_vesa_bank(bank_number);

	 /* how much can we copy in one go? */
	 if (todo > bank_size)
	    copy_size = bank_size;
	 else
	    copy_size = todo;

	 /* copy a bank of data to the screen */
	 dosmemput(memory_buffer, copy_size, 0xA0000);

	 /* move on to the next bank of data */
	 todo -= copy_size;
	 memory_buffer += copy_size;
	 bank_number += bank_size/bank_granularity;
      }
   }
```
The description of the above bank switching mechanism simplifies the issue because VESA supports two different banks (described as "windows" in the specification), which can be configured in various ways depending on the hardware. Usually, only one bank is used for reading and writing to video memory. Still, some boards may have two windows using different address ranges (e.g., one from **0xA0000** to **0xB0000** and another from **0xB0000** to **0xC0000** or two **32k** chunks, from **0xA0000** to **0xA8000** to **0xB0000**), or you could have one window for writing to the screen and a different one for reading from it, where each can be positioned independently of the other.

You don't need to worry about this when drawing to the screen, as long as you make sure to use the **WinSize** and **WinGranularity** values instead of assuming that the banks will always be **64k** in size. Still, checking the window settings before trying to read pixels from the screen is essential.

If the last bits in the **mode_info.WinAAttributes** field are **1**. The first window is readable and can proceed normally. If not, you have a second window for read operations, which means changing the **set_vesa_bank()** function to put a **1** in the **BX** register and writing to **mode_info.WinBSegment\*16** instead of the default address **0xA0000**.
