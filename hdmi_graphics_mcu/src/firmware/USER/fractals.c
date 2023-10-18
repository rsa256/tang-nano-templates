#include "fractals.h"
#include "systick.h"
#include "string.h"
#include <stdlib.h>
#include <stdio.h>
#include <bender.h>

#define MAXCOUNT 64 
// Function to draw mandelbrot set 
void fractal(float left, float top, float xside, float yside) 
{ 
    float xscale, yscale, zx, zy, cx, tempx, cy; 
    int x, y; 
    int maxx, maxy, count; 
  
    // getting maximum value of x-axis of screen 
    maxx = SCREEN_W - 1; 
  
    // getting maximum value of y-axis of screen 
    maxy = SCREEN_H - 1; 
  
    // setting up the xscale and yscale 
    xscale = xside / maxx; 
    yscale = yside / maxy; 
  
  
    // scanning every point in that rectangular area. 
    // Each point represents a Complex number (x + yi). 
    // Iterate that complex number 
    for (y = maxy/4 + 8; y <= maxy - 1; y++) { 
        for (x = 1; x <= maxx - 1; x++) 
        { 
            // c_real 
            cx = x * xscale + left; 
  
            // c_imaginary 
            cy = y * yscale + top; 
  
            // z_real 
            zx = 0; 
  
            // z_imaginary 
            zy = 0; 
            count = 0; 
  
            // Calculate whether c(c_real + c_imaginary) belongs 
            // to the Mandelbrot set or not and draw a pixel 
            // at coordinates (x, y) accordingly 
            // If you reach the Maximum number of iterations 
            // and If the distance from the origin is 
            // greater than 2 exit the loop 
            while ((zx * zx + zy * zy < 4) && (count < MAXCOUNT)) 
            { 
                // Calculate Mandelbrot function 
                // z = z*z + c where z is a complex number 
  
                // tempx = z_real*_real - z_imaginary*z_imaginary + c_real 
                tempx = zx * zx - zy * zy + cx; 
  
                // 2*z_real*z_imaginary + c_imaginary 
                zy = 2 * zx * zy + cy; 
  
                // Updating z_real = tempx 
                zx = tempx; 
  
                // Increment count 
                count = count + 1; 
            } 
  
            // To display the created fractal 
            setPixel(x, y, count); 
        } 
    } 
} 

#define SH 128
#define SW 128
uint32_t sa[SH][SW/32];
uint32_t sb[SH][SW/32];

int getCell(int x, int y) {
	if (x<0 || x>=SW || y<0 || y>=SH) return 0; 
	uint32_t mask = 0x80000000 >> (x & 0x1f);
	uint32_t data = sa[y][x >> 5];
	return (data & mask) ? 1 : 0;
}

const uint8_t bitCnt[8] = { 0, 1, 1, 2, 1, 2, 2, 3 };
int countCells(int x, int y) {
	int cx = x >> 5;
	int sm = 30 - (x & 0x1f);
	int cnt = 0;
	for (int cy = y-1; cy <= y+1; cy++) {
		uint32_t data = (sa[cy][cx]) >> sm;
		cnt += bitCnt[data & 0x07];
	}
	return cnt;
}

void setCell(int x, int y, int state) {
	uint32_t mask = 0x80000000 >> (x & 0x1f);
	if (state) {
		sb[y][x >> 5] |= mask;
	} else {
		sb[y][x >> 5] &= ~mask;
	}
}

void cellsDraw(int startX, int startY) {
	for (int y=0; y<SH; y++) {
		for (int x=0; x<SW/32; x++) {
			uint32_t data = sa[y][x];
			uint32_t mask = 0x80000000;
			int xOffset = (x << 5) + startX;
			for (int i=0; i<32; i++) {
				uint16_t color = data & mask ? BLACK : WHITE;
				setPixel(xOffset + i, y + startY, color);
				mask >>= 1;
			}
		}
	}
	commitPixels();
}

const uint16_t birth[] =   { 0b00001000, 0b00001000, 0b00001000, 0b00001000, 0b10001000, 0b10001000, 0b000000010, 0b000000010, 0b000000010, 0b111101000, 0b00111000, 0b00111000, 0b00000100, 0b00000100, 0b00011100, 0b00011100, 0b111011100, 0b111111100, 0b011111100, 0b111101100, 0b000001000, 0b110001000, 0b111110000, 0b111010000, 0b110001100, 0b000001100, 0b011110100, 0b000001000, 0b000001100, 0b011110100 };
const uint16_t survive[] = { 0b00001100, 0b00111110, 0b00111110, 0b00011110, 0b00111110, 0b00011110, 0b111111111, 0b111111111, 0b111111111, 0b111100000, 0b11110000, 0b11110000, 0b00000001, 0b00000000, 0b00000000, 0b00000000, 0b100000000, 0b100001101, 0b011110110, 0b011111110, 0b111110000, 0b111101100, 0b111100000, 0b111101000, 0b000011110, 0b000011100, 0b000000000, 0b100101111, 0b000011100, 0b000000000 };
const uint8_t init[] =     { 0x34,       0x31,       0xA1,       0x34,       0x34,       0x34,       0xFF,        0xFE,        0xFA,        0x57,        0x34,       0x29,       0x52,       0x52,       0xFD,       0x52,       0xFD,        0xFD,        0xFD,        0xFD,        0x49,        0x49,        0x4A,        0x4A,        0x51,        0x51,        0x51,        0x51,        0xFD,        0xFD };

int cellsStep(int lifeId) {
	uint16_t bp = birth[lifeId];
	uint16_t sp = survive[lifeId];
	
	for (int y=0; y<SH; y++) {
		for (int x=0; x<SW; x++) {
			int c = getCell(x,y);
			
			int xc = x & 0x1f;
			int n = 0;
			if (xc != 0 && xc != 31 && y !=0 && y != SH-1) {
				n = countCells(x,y) - c;
			} else {
				n += getCell(x-1, y-1);
				n += getCell(x, y-1);
				n += getCell(x+1, y-1);
				n += getCell(x-1, y);
				n += getCell(x+1, y);
				n += getCell(x-1, y+1);
				n += getCell(x, y+1);
				n += getCell(x+1, y+1);
			}

			uint16_t mask = 1 << n;
			if (c) {
				// Survive
				if (!(sp & mask)) setCell(x, y, 0);
			} else {
				// Birth
				if (bp & mask) setCell(x, y, 1);
			}
		}
	}
	int compare = memcmp(sa, sb, SH*SW/8);
	memcpy(sa, sb, SH*SW/8);
	return compare;
}

void paternToStr(char *s, uint16_t pattern) {
	int p = 0;
	for (int i=0; i<9; i++) {
			if (pattern & ( 1 << i)) {
				s[p++] = '0' + i;
			}
	}
	s[p] = 0;
}

void printPattern(int lifeId, int x, int y) {
	char bp[10];
	char sp[10];
	char s[32];
	paternToStr(bp, birth[lifeId]);
	paternToStr(sp, survive[lifeId]);
	sprintf(s, "B%s/S%s/I%02x", bp, sp, init[lifeId]);
	setCursor(x, y);
	setText(s, YELLO);
}

void cellsInit(int initId) {
	memset(sb, 0, SH*SW/8);
	if (initId == 0xff) {
		setCell(SW/2, SH/2, 1);
	} else 
	if (initId == 0xfe) {
		setCell(0, 0, 1);
		setCell(SW-1, 0, 1);
		setCell(0, SH-1, 1);
		setCell(SW-1, SH-1, 1);
	} else
	if (initId == 0xfd) {
		setCell(SW/2, SH/2, 1);
		setCell(SW/2-1, SH/2, 1);
		setCell(SW/2, SH/2-1, 1);
		setCell(SW/2-1, SH/2-1, 1);
	} else {		
		int randArea = initId & 0x0f;
		if (randArea > 10) randArea = 10;
		int fillRate = (initId >> 4) & 0x0f;
		fillRate = (fillRate <= 10) ? 1024*fillRate/10 : 1;
		
		int offset = SH * (10 - randArea) / 20;
		for (int y=offset; y<SH-offset; y++) {
			for (int x=offset; x<SW-offset; x++) {
				int r = rand();
				r = (r ^ (r >> 16)) & 0x3ff;
				setCell(x, y, r < fillRate);
			}
		}
	}
	memcpy(sa, sb, SH*SW/8);
}


void cells() {
	for (int lifeId=0; lifeId < sizeof(init); lifeId++) {
		int initId = init[lifeId];
		cellsInit(initId);
		int startX = lifeId*SW % SCREEN_W;
		int startY = (lifeId*SW / SCREEN_W) * (SH + font->FontHeight);
		printPattern(lifeId, startX, startY + SH);
		cellsDraw(startX, startY);
		if (startX + SW + FarnsworthWidth <= SCREEN_W) {
			printImage(Farnsworth, startX + SW, startY, FarnsworthWidth, FarnsworthHeight);
		}
		delay_us(1000000);
		for (int step=0; step<100; step++) {
			if (cellsStep(lifeId) == 0) break;
			cellsDraw(startX, startY);
			delay_us_last(1000000/37);
		}
	}
}
