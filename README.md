# tang-nano-templates
Template projects for TangNano-4k and TangNano-9k with video out on HDMI

hdmi_graphics_mcu
- requires TangNano-4k and HDMI display
- HDMI FullHD 1920x1080 output
- HyperRAM based VideoRAM, RGB565 pixel mode
- Hardware Cortext-M3, 92Mhz, 8K SRAM, 32k flash with APB interface to VideoRAM
- GPU firmware library to access VideoRAM with basic graphics (pixel, line, text, fill)
- Systick presise time measurement
- MCU Hardware UART for STDOUT at 11500 baud
- demo firmware Keil project: Cellular automaton, fractals, text output, compressed image output, performance benchmarks

hdmi_terminal_mcu
- requires TangNano-4k and HDMI display
- implements hardware text ASCI terminal
- HDMI HD 1280x720 output
- supports CR, LF, Home and auto scroll
- blink cursor
- BSRAM based TextRAM with 8x8 hardware font
- Hardware Cortext-M3, uart output connected to hardware terminal
- Systick presise time measurement
- demo firmware Keil project: sysinfo ouptut to the terminal using printf

hdmi_terminal_uart
- requires TangNano-4k and HDMI display
- implements hardware text ASCI terminal
- HDMI HD 1280x720 output
- supports CR, LF, Home and auto scroll
- blink cursor
- BSRAM based TextRAM with 8x8 hardware font
- hardware UART input connected to PIN44

TangNano-9K-LCD-Spectrum
- requires TangNano-9k and paralel digital VGA LCD (Reference KIT https://www.aliexpress.com/item/1005004275539854)
- 3x pixel upscale for optumum usage of 7" 1024x600 LCD
- implements hardware ULA https://sinclair.wiki.zxnet.co.uk/wiki/ZX_Spectrum_ULA with hi-speed SPI interface
- easy connection to MCU based ZX-spectrun emulators via 3pins SPI CS,CK,DO and VSYNC output to emulator IRQ
- MCU emulator must update whole ZX videoRAM content 6144 bitmap + 768 attributes + Border color bytes every frame
- implement Bitmap, Atributes colors, blink cursor and Border
- true 50HZ frame rate with VSYNC
- Additional 2x32 ASCII chars organized as 2 lines below the main screen for Emulator state output

