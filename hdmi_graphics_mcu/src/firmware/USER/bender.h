/*
 * bender.h
 *
 *  Created on: 28Sep.,2023
 *      Author: mrsa256
 */
#ifndef USER_BENDER_H_
#define USER_BENDER_H_

#include <stdint.h>

#define BenderWidth 132
#define BenderHeight 192
#define FarnsworthWidth 124
#define FarnsworthHeight 128
#define BenderBackground 0xffff
extern const uint16_t Bender[];
extern const uint16_t Farnsworth[];

void printImage(const uint16_t image[], int startX, int startY, int width, int height);

#endif /* USER_BENDER_H_ */
