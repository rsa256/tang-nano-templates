/*
 ******************************************************************************************
 * @file      gpu.h
 * @author    mrsa256
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     HDMI graphics interface
 ******************************************************************************************
 */

#ifndef GPU_H
#define GPU_H

/* Includes ------------------------------------------------------------------*/
#include "gw1ns4c.h"
#include "Display_fonts.h"

/* Definitions ------------------------------------------------------------------*/
//type definition
typedef struct
{
  __O    uint32_t  DATA[32];          /* Offset: 0x000 (W) [7:0] */
  __O    uint32_t  ADDR;      	      /* Offset: 0x080 (W) [7:0] */
	__O    uint32_t  MASK0;      	      /* Offset: 0x084 (W) [7:0] */
	__O    uint32_t  MASK1;      	      /* Offset: 0x088 (W) [7:0] */
  __IO   uint32_t  CMD;               /* Offset: 0x08C (R/W) [1:0] */
}GPU_TypeDef;

//base address
#define GPU_BASE   (APB2PERIPH_BASE + 0x400)

//mapping
#define GPU        ((GPU_TypeDef   *) GPU_BASE)

//bit definition
#define STATUS_WRITE_PROGRESS		((uint32_t) 0x00000001)

/* Declarations ------------------------------------------------------------------*/
void setPixels(uint32_t addr, uint16_t* colors);
void setPixel(int x, int y, uint16_t color);
void commitPixels(void);
void setLine(int XS, int YS, int XE, int YE, uint16_t color);
void setChar(int x, int y, uint16_t color, char c);
void setText(char* str, uint16_t color);
void setCursor(int x, int y);
	
int  getWriteProgressStatus(void);
void clearScreen(uint16_t color);

extern FontDef *font;

#define SCREEN_W 1920
#define SCREEN_H 1080

#define BLACK 0x0000
#define WHITE 0xffff
#define RED 	0xf800
#define GREEN	0x07e0
#define BLUE  0x001f
#define CYAN  0x07ff
#define YELLO 0xffe0

#endif
