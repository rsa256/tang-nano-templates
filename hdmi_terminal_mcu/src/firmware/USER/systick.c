#include "systick.h"
#include "gw1ns4c.h"

#include <stdio.h>

int SysTick_Frequency;
volatile int tickSec10 = 0;
long long start_us, delay_start_us;

void (*systick_callback)(int) = 0;

void SysTick_init(void) {
	SystemCoreClockUpdate();
	SysTick_Frequency = SystemCoreClock;
	// Reload every 1/10 sec
	SysTick_Config(SysTick_Frequency/10);
	SysTick_CLKSourceConfig(SysTick_CLKSource_HCLK);
}

static __inline int SysTick_GetCounter(void)
{
  return(SysTick->VAL);
}


/**
  * @brief  This function handles SysTick Handler.
  * @param  None
  * @retval None
  */
void SysTick_Handler(void)
{
	tickSec10++;
	static uint8_t sec10cnt = 0;
	if (systick_callback && (sec10cnt++ == 10)) {
		sec10cnt = 0;
		systick_callback(tickSec10 / 10);
	}
}

long long getRunTime(void) {
	int tics = SysTick_GetCounter();
	long long sec10 = tickSec10;
	long long difTick = (SysTick_Frequency - 1) - tics;
	return sec10*100000 + difTick*1000000/SysTick_Frequency;
}

long getRunTimeSec(void) {
	return tickSec10/10;
}

void initTime(void) {
	start_us = getRunTime();
}

long long getTime(void) {
	return getRunTime() - start_us;
}

void printTime(void) {
	printf("Done (%lld mks)\n\r", getTime());
	initTime();
}

void delay_us(int us_value) {
	long long end_us = getRunTime() + us_value;
	while (end_us > getRunTime());
}

void delay_us_last(int us_value) {
	long long end_us = delay_start_us + us_value;
	while (end_us > getRunTime());
	delay_start_us = end_us;
}

void delay_tick(int tics) {
	int waitTick = (SysTick->VAL - tics);
	int waitSec10 = tickSec10;
	if (waitTick < 0) {
		waitTick += SysTick_Frequency;
		waitSec10++;
	}
	
	while ((waitSec10 != tickSec10)||(waitTick < SysTick->VAL)) {
		if (waitSec10 < tickSec10) break;
	}
}

/*********************************************************************************************************
      END FILE
*********************************************************************************************************/
