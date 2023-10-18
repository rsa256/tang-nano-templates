/*
 ******************************************************************************************
 * @file      main.c
 * @author    mrsa256
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     Main program body.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "gw1ns4c.h"
#include <stdlib.h>
#include <stdio.h>
#include "bender.h"
#include "systick.h"
#include "gpu.h"
#include "math.h"
#include "fractals.h"

/* Declarations ------------------------------------------------------------------*/
void printSpeed(char *caption);
void GPIOInit(void);
void UartInit(void);

/* Functions ------------------------------------------------------------------*/
int main(void)
{
	SystemInit();	//Initializes system
	GPIOInit();		//Initializes GPIO
  UartInit();   //Initializes UART

	printf("Clock Speed %d Hz\n\r", SystemCoreClock);

  SysTick_init();
	
	delay_us(100000);
	initTime();
	
	
	clearScreen(CYAN);
	printTime();

  //printBender();
	
	/*
	uint16_t colors[64];
	
	for (int y=0; y<64; y++) {
		for (int x=0; x<64; x++) {
			//colors[x] = (x == y) ? 0x07e0 : 0x0000; 
			colors[x] = (x == y) ? 0x07e0 : 0x0000; 
			setPixel(x, y+200, 0xffff);
		}
		setPixels((y + 200)*1920*8 + 256, colors);
		while (getFinishStatus() == 0);
		setPixels((y + 413)*1920*4 + 512, colors);
		while (getFinishStatus() == 0);
		setPixels((y + 522)*1920*2 + 1024, colors);
		while (getFinishStatus() == 0);
	}
	*/
	
	
	char str[64];
	setCursor(0, SCREEN_H - font->FontHeight * 2);
	sprintf(str, "Hello world from CortexM3 MCU!");
	setText(str, WHITE);
	setCursor(0, SCREEN_H - font->FontHeight * 1);
  sprintf(str, "Clock Speed %d Hz", SystemCoreClock);
	setText(str, GREEN);
	printTime();
	
		/*
	int16_t color = 0;
	for (float i=0; i<2*3.1415; i+=0.01) {
			int x = 1920/2 + 300*cos(i);
			int y = 100 + 100*sin(i);
			
			setLine(1920/2, 100, x, y, color++);
			//setText("Hello World! ", color);
	}
	printTime();
	*/
 
 	cells();
	printTime();
	
	// setting the left, top, xside and yside 
	// for the screen and image to be displayed 
	float left = -1.75; 
	float top = -0.25; 
	float xside = 0.45; 
	float yside = 0.45; 
	fractal(left, top, xside, yside); 
	printTime();

  // Random chars
	for (int n=0; n<1000; n++) {
		initTime();
		for (int i=0; i<100; i++) {
			char c = 0x20 + rand() % (0x80 - 0x20);
			int x = rand() % SCREEN_W;
			int y = rand() % SCREEN_H;
			uint16_t color = rand();
			setChar(x, y, color, c);
		}
		printSpeed("Chars");
	}
	
  // Random lines
	for (int n=0; n<50; n++) {
		initTime();
		for (int i=0; i<100; i++) {
			int xs = rand() % SCREEN_W;
			int ys = rand() % SCREEN_H;
			int xe = rand() % SCREEN_W;
			int ye = rand() % SCREEN_H;
			uint16_t color = rand();
			setLine(xs, ys, xe, ye, color);
		}
		printSpeed("Lines");
	}

  // Benders
	int togleLed = 0;
	while (1) {
		initTime();
		for (int i=0; i<100; i++) {
			int x = rand() % SCREEN_W;
			int y = rand() % SCREEN_H;
			if (togleLed) {
				GPIO_ResetBit(GPIO0,GPIO_Pin_0);  //LED on
			} else {
				GPIO_SetBit(GPIO0,GPIO_Pin_0);  //LED on
			}
			togleLed ^= 1;
			printImage(Bender, x, y, BenderWidth, BenderHeight);
		}
		printSpeed("Benders");
	}

}

// Output test performance
void printSpeed(char *caption)
{
		char str[64];
		setCursor(SCREEN_W/2, SCREEN_H/2 - 10);
	  sprintf(str, "%.02f %s/sec", 100*1e6/getTime(), caption);
		setText(str, GREEN);
}

//Initializes GPIO
void GPIOInit(void)
{
	GPIO_InitTypeDef GPIO_InitType;
	
	GPIO_InitType.GPIO_Pin = GPIO_Pin_0;
	GPIO_InitType.GPIO_Mode = GPIO_Mode_OUT;
	GPIO_InitType.GPIO_Int = GPIO_Int_Disable;

	GPIO_Init(GPIO0,&GPIO_InitType);

  GPIO_SetBit(GPIO0,GPIO_Pin_0);
}


//Initializes UART
void UartInit(void)
{
    UART_InitTypeDef UART_InitStruct;

    UART_InitStruct.UART_Mode.UARTMode_Tx = ENABLE;
    UART_InitStruct.UART_Mode.UARTMode_Rx = ENABLE;
    UART_InitStruct.UART_Int.UARTInt_Tx   = DISABLE;
    UART_InitStruct.UART_Int.UARTInt_Rx   = DISABLE;
    UART_InitStruct.UART_Ovr.UARTOvr_Tx   = DISABLE;
    UART_InitStruct.UART_Ovr.UARTOvr_Rx   = DISABLE;
    UART_InitStruct.UART_Hstm             = DISABLE;
    UART_InitStruct.UART_BaudRate         = 115200;

    UART_Init(UART0,&UART_InitStruct);
}
