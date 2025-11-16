// usb.h
/*
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/
// header file for spi funcions

#include <stdint.h>
#include <stm32l432xx.h>
#include "STM32L432KC_TIM.h"
#include "STM32L432KC_RCC.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_FLASH.h"
#include "STM32L432KC_SPI.h"
#include "usb.h"
#include "main.h"

#define REG_REVISION  18

#define MAX_CMD_READ(reg)  (uint8_t)(((reg) << 3) | 0x00)  // DIR=0
#define MAX_CMD_WRITE(reg) (uint8_t)(((reg) << 3) | 0x02)  // DIR=1




void init_usb(void){
  uint8_t address = MAX_CMD_WRITE(17);
  spiwrite(address,0x10);
  //delay_millis(TIM15, 1000);
}



static uint8_t max_read_reg(uint8_t reg)
{
    uint8_t cmd = MAX_CMD_READ(reg);
    uint8_t val;

    enable_cs(); // CS low
    (void)spiSendReceive(cmd);   // clocks out host status bits; ignore for now
    val = spiSendReceive(0x00);  // now get the register contents
    disable_cs(); // CS high

    return val;
}

static void max_write_reg(uint8_t reg, uint8_t val)
{
    uint8_t cmd = MAX_CMD_WRITE(reg);

    enable_cs(); // CS low
    (void)spiSendReceive(cmd);   // status
    (void)spiSendReceive(val);   // data (returned byte is don't-care)
    disable_cs(); // CS high
}

void max_basic_test(void)
{
    // 1) HW reset line low then high if you have it
    // gpio_write(MAX_RES_PIN, 0); delay_ms(1);
    // gpio_write(MAX_RES_PIN, 1); delay_ms(10);

    // 2) Read REVISION register
    uint8_t rev = max_read_reg(REG_REVISION);

    // 3) Inspect 'rev' with your debugger / UART
    // e.g. printf("MAX3421E REV = 0x%02X\n", rev);
}

