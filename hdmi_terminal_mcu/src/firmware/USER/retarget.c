/*
 ******************************************************************************************
 * @file      retarget.c
 * @author    GowinSemiconductor
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     UART printf and scanf retarget function.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "gw1ns4c.h"
#include <stdio.h>

#pragma import (__use_no_semihosting_swi)

struct __FILE
{
    int handle;
};

FILE __stdout;
FILE __stdin;
FILE __stderr;

int fputc(int ch, FILE *f)
{
	UART_SendChar(UART0, (uint8_t) ch);
	while(UART0->STATE & UART_STATE_TXBF);//UART0
	
	return (ch);
}

int fgetc(FILE *f)
{
	while(!(UART0->STATE & UART_STATE_RXBF));//UART0
	
	return (int)UART_ReceiveChar(UART0);
}

void _ttywrch(int ch)
{
	UART_SendChar(UART0, (uint8_t) ch);
	while(UART0->STATE & UART_STATE_TXBF);//UART0
}

int _ferror(FILE *f)
{
  /* Your implementation of ferror */
  return EOF;
}

void _sys_exit(int return_code)
{
    //x = x;
label:goto label;
}
