/*
File: main.c
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/


#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"
#include "STM32L432KC_SPI.h"
#include "random.h"


/////////////////////////////////////////////////////////////////
// Provided Constants and Functions
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// Solution Functions
/////////////////////////////////////////////////////////////////

int main(void) {
  configureFlash();
  configureClock();

  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);

  pinMode(RESET_N, GPIO_OUTPUT);
  //digitalWrite(RESET_N, 0);


  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
  initTIM(TIM15);
  //delay_millis(TIM15, 1000);

  RCC->APB2ENR |= (1 << 12); // ENABLE SPI1

  configureSPIPins();

  initSPI(0b111, 0, 0);
  //digitalWrite(RESET_N, 1);

  initRandomGenerator();

  USART_TypeDef * USART = initUSART(USART1_ID, 11500);

  //getTemperatureData();
  int counter = 0;
  while(1) {
    /* Wait for ESP8266 to send a request.
    Requests take the form of '/REQ:<tag>\n', with TAG begin <= 10 characters.
    Therefore the request[] array must be able to contain 18 characters.
    */

    //float temperature = getTemperatureData();
    //float temperature = 0;
    //char temperature_string[32];
    //sprintf(temperature_string,"Temperature is %0.4f C", temperature);

    // Wait for a complete request to be transmitted before processing

    char request[BUFF_LEN] = "                  "; // initialize to known value
    int charIndex = 0;
    if((USART->ISR & USART_ISR_RXNE)) {
      // Keep going until you get end of line character
      while(charIndex < 8) {
        // Wait for a complete request to be transmitted before processing
        while(!(USART->ISR & USART_ISR_RXNE));
        char readCharecter = readChar(USART);
        printf("%x", readCharecter);
        request[charIndex++] =  readCharecter;
      }
     printf("Received request: %s\n", request);
  }

    // Update string with current LED state
    counter += 1;
    uint32_t randnum = getRandomNumber();
    //printf("%d",randnum);
    enable_cs();
    spiSendReceive(randnum & 0xFF);
    disable_cs();
    //delay_millis(TIM15, 5000);
    }
}
