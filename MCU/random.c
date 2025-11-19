// random.c
/*
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/
// random init functions
#include <stdint.h>
#include <stm32l432xx.h>
#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_FLASH.h"
#include "main.h"


void initRandomGenerator(){
    //enable RNG clock
    RCC->AHB2ENR |= RCC_AHB2ENR_RNGEN;
    //enable RNG
    RNG->CR |= RNG_CR_RNGEN;
    // 1. Turn on HSI48 (RNG dedicated clock source)
    RCC->CRRCR |= RCC_CRRCR_HSI48ON;
    while ((RCC->CRRCR & RCC_CRRCR_HSI48RDY) == 0) {
        // wait until 48 MHz RC is stable
    }

    // 2. Enable AHB2 clock for RNG (rng_hclk domain)
    RCC->AHB2ENR |= RCC_AHB2ENR_RNGEN;  

    RNG->CR |= 0x1UL << 5U; 
}

uint32_t getRandomNumber(){
    //wait until data is ready
    while(~(~RNG_SR_SEIS | ~RNG_SR_CEIS | RNG_SR_DRDY)){
       RNG->SR &= ~_VAL2FLD(RNG_SR_SEIS, 1);
       RNG->SR &= ~_VAL2FLD(RNG_SR_CEIS, 1);
    }

    //read random number
    return(RNG->DR);
}
