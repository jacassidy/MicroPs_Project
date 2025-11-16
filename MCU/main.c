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
#include "usb.h"

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
  digitalWrite(RESET_N, 0);
 
  
  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
  initTIM(TIM15);
  delay_millis(TIM15, 1000);

  RCC->APB2ENR |= (1 << 12); // ENABLE SPI1

  configureSPIPins();

  initSPI(0b111, 0, 0);  
  digitalWrite(RESET_N, 1);
  delay_millis(TIM15, 1000);

  init_usb();

  max_basic_test();

  //getTemperatureData();
    
  while(1) {
    /* Wait for ESP8266 to send a request.
    Requests take the form of '/REQ:<tag>\n', with TAG begin <= 10 characters.
    Therefore the request[] array must be able to contain 18 characters.
    */

    //float temperature = getTemperatureData();
    //float temperature = 0;
    //char temperature_string[32];
    //sprintf(temperature_string,"Temperature is %0.4f C", temperature);
    
    // Update string with current LED state

  }
}
