// STM32L432KC_SPI.c
/*
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/
// difines functions for SPI communication on the STM32L432KC microcontroller

#include <stdint.h>
#include <stm32l432xx.h>
#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_FLASH.h"
#include "main.h"

void initSPI(int br, int cpol, int cpha) {
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_BR, br); // BR

    SPI1->CR1 &= ~(1 << 1); // clock polarity
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPOL, cpol);

    SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPHA, cpha); // clock phase

    SPI1->CR1 &= ~(SPI_CR1_BIDIMODE | SPI_CR1_RXONLY | SPI_CR1_LSBFIRST); // BIDIMODE -> unidirectional // RXONLY --> fully duplex // send and recv with MSB first

    SPI1->CR1 |= _VAL2FLD(SPI_CR1_SSI, 1); // sl*** select management
    SPI1->CR1 |= _VAL2FLD(SPI_CR1_SSM, 1);

    SPI1->CR1 |= _VAL2FLD(SPI_CR1_MSTR, 1); // set MCU as master

    SPI1->CR2 |= _VAL2FLD(SPI_CR2_DS, 0b0111); // set data size to 8 bits

    SPI1->CR2 &= ~(SPI_CR2_SSOE | SPI_CR2_FRF | SPI_CR2_NSSP); // SSOE disable to control from software // motorola // for manual CS pulse generation

    SPI1->CR2 |= _VAL2FLD(SPI_CR2_FRXTH, 1); // set FIFO size to 8 bits

    SPI1->CR1 |= _VAL2FLD(SPI_CR1_SPE, 1); // SPI enable

    RCC->APB2ENR |= (1 << 12); // ENABLE SPI1
}


uint8_t spiSendReceive(uint8_t send) {
    while(!(SPI1->SR & SPI_SR_TXE));                        // wait until transmit buffer is empty
    *(volatile uint8_t *) (&SPI1->DR) = send;               // set the data register
    while(!(SPI1->SR & SPI_SR_RXNE));                       // wait until receive buffer not empty
    volatile uint8_t data = (volatile uint8_t) SPI1->DR;    // read data
    return(data);
}

void enable_cs(){
  digitalWrite(SPI_CE, 0); //active low
}

void disable_cs(){
digitalWrite(SPI_CE, 1); //disactive high
}

uint8_t spiwrite(uint8_t address, uint8_t val) {
  enable_cs();
  uint8_t status = spiSendReceive(address);
  spiSendReceive(val);
  disable_cs();
  return status; 
}

void configureSPIPins()
{
    pinMode(SPI_SCK, GPIO_ALT); // SPI1_SCK
    pinMode(SPI_MISO, GPIO_ALT); // SPI1_MISO
    pinMode(SPI_MOSI, GPIO_ALT); // SPI1_MOSI
    pinMode(SPI_CE, GPIO_OUTPUT); //  Manual CS
    disable_cs(); // set CS to low

    //// Set output speed type to high for SCK
    GPIOB->OSPEEDR &= ~(GPIO_OSPEEDR_OSPEED3);
    GPIOB->OSPEEDR |= (GPIO_OSPEEDR_OSPEED3);
    GPIOB->OSPEEDR &= ~(GPIO_OSPEEDR_OSPEED4);
    GPIOB->OSPEEDR |= (GPIO_OSPEEDR_OSPEED4);
    GPIOB->OSPEEDR &= ~(GPIO_OSPEEDR_OSPEED5);
    GPIOB->OSPEEDR |= (GPIO_OSPEEDR_OSPEED5);

    //// Set to AF05 for SPI alternate functions
    GPIOB->AFR[0] &= ~(_VAL2FLD(GPIO_AFRL_AFSEL3, 5));
    GPIOB->AFR[0] &= ~(_VAL2FLD(GPIO_AFRL_AFSEL4, 5));
    GPIOB->AFR[0] &= ~(_VAL2FLD(GPIO_AFRL_AFSEL5, 5));
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL3, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL4, 5);
    GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL5, 5);
}

