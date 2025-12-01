// STM32F401RE_TIM.h
// Header for TIM functions

#ifndef STM32L4_TIM_H
#define STM32L4_TIM_H

#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>  // CMSIS device library include
#include "STM32L432KC_GPIO.h"

#include <stdbool.h>


///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void initTIM(TIM_TypeDef * TIMx);
void delay_millis(TIM_TypeDef * TIMx, uint32_t ms);
void begin_timer(TIM_TypeDef * TIMx, uint32_t ms);
bool check_timer(TIM_TypeDef * TIMx);

#endif