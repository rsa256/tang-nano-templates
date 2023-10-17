/*
 ******************************************************************************************
 * @file      systick.h
 * @author    mrsa256
 * @brief     ARM core precise timing functuins
 ******************************************************************************************
 */
 
#ifndef __SYSTICK_H
#define __SYSTICK_H 

void SysTick_init(void);

void initTime(void);
long long getTime(void);
void printTime(void);

long long getRunTime(void);
long getRunTimeSec(void);

void delay_us(int us_value);
void delay_us_last(int us_value);

void delay_tick(int tics);

// Optional calback for every second event
extern void (*systick_callback)(int);

#endif
/*********************************************************************************************************
      END FILE
*********************************************************************************************************/
