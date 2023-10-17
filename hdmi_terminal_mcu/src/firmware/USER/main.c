/*
 ******************************************************************************************
 * @file      main.c
 * @author    GowinSemiconductor
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     Main program body.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "gw1ns4c.h"
#include "stdio.h"
#include "systick.h"
#include "bender.h"

/* Declarations ------------------------------------------------------------------*/
void GPIOInit(void);
void UartInit(void);

/* Functions ------------------------------------------------------------------*/
int main(void)
{
	SystemInit();	//Initializes system
	GPIOInit();		//Initializes GPIO
  UartInit();   //Initializes UART
	SysTick_init();
	
  printBender();
	printf("%c", 1);

  int counter = 0;
  while(1)
  {
        GPIO_ResetBit(GPIO0,GPIO_Pin_0);  //LED on
        delay_us_last(500000);

        GPIO_SetBit(GPIO0,GPIO_Pin_0);    //LED off
        delay_us_last(500000);

        printf("Hello world from CortexM3 MCU!, counter value = %d\n\r", counter++);
        printf("Clock Speed %d Hz\n\r", SystemCoreClock);
        printTime();
  }
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
