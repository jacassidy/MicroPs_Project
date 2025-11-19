// random.h
/*
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/
// header file for random funcions


#include <stdint.h>
#include <stm32l432xx.h>

#ifndef random_H
#define random_H
void initRandomGenerator();

uint32_t getRandomNumber();

#endif
