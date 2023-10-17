/* Includes ------------------------------------------------------------------*/
#include "gpu.h"

/* Functions ------------------------------------------------------------------*/
void setPixels(uint32_t addr, uint16_t* colors)
{
	for (int i=0; i < 32; i++) {
		uint32_t data = (*(colors+1) << 16 ) | *colors;
		colors += 2;
		GPU->DATA[i] = data;
	}
	GPU->MASK0 = 0;
	GPU->MASK1 = 0;
	GPU->ADDR = addr;
}

uint16_t pix_buf[64];
uint32_t pix_addr = 0xffffffff;
uint32_t pix_mask1;
uint32_t pix_mask2;

void commitPixels(void) {
		uint32_t* buf_ptr = (uint32_t*)&pix_buf;
		for (int i=0; i < 32; i++) {
			GPU->DATA[i] = buf_ptr[i];
		}
		GPU->MASK0 = ~pix_mask1;
		GPU->MASK1 = ~pix_mask2;
		GPU->ADDR = pix_addr;
		pix_mask1 = 0;
		pix_mask2 = 0;
		while (getWriteProgressStatus());
}

void setPixel(int x, int y, uint16_t color)
{
	uint32_t pixid = y*SCREEN_W + x;
	uint32_t addr = (pixid & 0xffffffc0) << 1;
	int mask = pixid & 0x3f;

	if (addr != pix_addr) {
		commitPixels();
		pix_addr = addr;
	}
	pix_buf[mask] = color;
	if (mask < 0x20) {
		pix_mask1 |= (0x80000000 >> mask);
	} else {
		pix_mask2 |= (0x80000000 >> (mask - 0x20));
	}
}

void setLine(int XS, int YS, int XE, int YE, uint16_t color) {
	int32_t Cnt, Distance;
	int32_t XErr = 0, YErr = 0, dX, dY;
	int32_t XInc, YInc;

	dX = XE-XS;
	dY = YE-YS;

	if(dX>0) XInc = 1;
	else if(dX==0) XInc = 0;
	else XInc = -1;

	if(dY>0) YInc = 1;
	else if(dY==0) YInc = 0;
	else YInc = -1;

	dX = dX >=0 ? dX : -dX;
	dY = dY >=0 ? dY : -dY;

	if(dX>dY) Distance = dX;
	else Distance = dY;


	for(Cnt = 0; Cnt<=Distance+1; Cnt++){
		setPixel(XS,YS, color);

		XErr+=dX;
		YErr+=dY;
		if(XErr>Distance){
			XErr-=Distance;
			XS+=XInc;
		}
		if(YErr>Distance){
			YErr-=Distance;
			YS+=YInc;
		}
	}
}

FontDef *font = &Font_7x10;
void setChar(int x, int y, uint16_t color, char c) {
	if (c < 0x20) return; 
	for (int dy=0; dy<font->FontHeight; dy++) {
		uint16_t line = font->data[(c - 0x20)*(font->FontHeight) + dy];
		for (int dx=0; dx<font->FontWidth; dx++) {
			uint16_t fc = line & 0x8000 ? color : BLACK;
			line = line << 1;
			setPixel(x + dx, y + dy, fc);
		}
	}
}

int cursorX = 0;
int cursorY = 0;

void setCursor(int x, int y) {
		cursorX = x;
		cursorY = y;
}

void setText(char* str, uint16_t color) {
	char c = *str;
	while (c!=0) {
		if (c == 0x0a) {
				cursorY += font->FontHeight;
				if (cursorY + font->FontHeight >= SCREEN_H) {
					cursorY = 0;
				}
		} else if (c == 0x0d) {
				cursorX = 0;
		} else {
			setChar(cursorX, cursorY, color, c);
			cursorX += font->FontWidth;
			if (cursorX + font->FontWidth > SCREEN_W) {
				cursorX = 0;
				cursorY += font->FontHeight;
				if (cursorY + font->FontHeight > SCREEN_H) {
					cursorY = 0;
				}
			}
		}
		c = *++str;
	}
}
	
	
void clearScreen(uint16_t color) {
	uint32_t data = (color << 16 ) | color;
	for (int i=0; i < 32; i++) {
		GPU->DATA[i] = data;
	}
	GPU->MASK0 = 0;
	GPU->MASK1 = 0;
	for (uint32_t addr = 0; addr<SCREEN_W*SCREEN_H*2; addr +=128) {
			GPU->ADDR = addr;
			while (getWriteProgressStatus());
	}
}

int getWriteProgressStatus(void) {
	return GPU->CMD & STATUS_WRITE_PROGRESS;
}

