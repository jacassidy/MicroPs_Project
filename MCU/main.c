/*
File: main.c
Author: Noah Fotenos
Email: nfotenos@g.hmc.edu
Date: 11/6/25
*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "main.h"
#include "STM32L432KC_SPI.h"
#include "random.h"
#include "stm32l4xx.h"

#include "ps2_keyboard.h"
#include "spi_protocol.h"

//// ---- Module-level variables ---- ////

USART_TypeDef *USART;  // handle for USART1 from initUSART()

// Edge-detect state for arrow keys
static uint8_t last_up    = 0;
static uint8_t last_down  = 0;
static uint8_t last_left  = 0;
static uint8_t last_right = 0;

//// -----------------------------------------------------------------
////  Helper functions: each does "one thing" and keeps main readable
//// -----------------------------------------------------------------

// Configure flash wait-states and system clock tree
static void system_init_clocks_and_flash(void) {
    configureFlash();
    configureClock();
}

// Enable GPIO clocks and basic board I/O
static void system_init_gpio(void) {
    gpioEnable(GPIO_PORT_A);
    gpioEnable(GPIO_PORT_B);
    gpioEnable(GPIO_PORT_C);

    pinMode(RESET_N, GPIO_OUTPUT);
    //digitalWrite(RESET_N, 0);
}

// Enable and configure TIM15/TIM16
static void system_init_timers(void) {
    // Enable timer peripheral clocks
    RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
    RCC->APB2ENR |= (RCC_APB2ENR_TIM16EN);

    initTIM(TIM15);
    initTIM(TIM16);
}

// Start any periodic timers used by the application
static void system_start_timers(void) {
    begin_timer(TIM15, 1000);   // 1-second initial period (random update)
    begin_timer(TIM16, 1000);   // used by keyboard_update_state() gating
}

// Configure SPI signals + random number generator used in SPI payload
static void system_init_spi_and_random(void) {
    // Enable SPI1 peripheral clock
    RCC->APB2ENR |= (1 << 12);

    configureSPIPins();
    initSPI(0b111, 0, 0);

    initRandomGenerator();
}

// Configure USART1 to receive PS/2 bitstream and enable its interrupt
static void system_init_usart_ps2(void) {
    USART = initUSART(USART1_ID, 11500);  // same baud as original code

    // Enable RXNE interrupt on this USART
    USART->CR1 |= USART_CR1_RXNEIE;

    // Enable USART1 interrupt line in the NVIC (ISR in ps2_keyboard.c)
    NVIC_EnableIRQ(USART1_IRQn);
}

// Poll the PS/2 mailbox and update the internal keyboard state
static void update_keyboard_state(void) {
    // All the heavy lifting is inside ps2_keyboard.c
    scanKeyboard();
}

// Look for new arrow-key presses and send a corresponding SPI word
static void handle_arrow_key_edges(void) {
    // Current snapshot of arrow keys
    uint8_t up_now    = keyboard_get_key_state('^');
    uint8_t down_now  = keyboard_get_key_state('v');
    uint8_t left_now  = keyboard_get_key_state('<');
    uint8_t right_now = keyboard_get_key_state('>');

    // Edge-detect: send a word only when key transitions 0 -> 1
    if (up_now && !last_up) {
        // key_value = 1 for Up
        send_spi_word(1, 1);
    } else if (down_now && !last_down) {
        // key_value = 0 for Down
        send_spi_word(1, 0);
    } else if (left_now && !last_left) {
        // key_value = 2 for Left
        send_spi_word(1, 2);
    } else if (right_now && !last_right) {
        // key_value = 3 for Right
        send_spi_word(1, 3);
    }

    // Latch for next iteration
    last_up    = up_now;
    last_down  = down_now;
    last_left  = left_now;
    last_right = right_now;
}

// Periodically refresh the 3-bit random field used in the SPI payload
static void handle_periodic_random_update(void) {
    if (check_timer(TIM15)) {
        update_random3();          // defined in spi_protocol.c
        //send_spi_word(0, 0);     // optional idle / heartbeat packet
        begin_timer(TIM15, 5000);  // 5-second period after first tick
    }
}

/////////////////////////////////////////////////////////////////
// main()
//  - Initialize hardware
//  - Run control loop:
//      * update keyboard from PS/2
//      * detect arrow presses
//      * periodically update random bits
/////////////////////////////////////////////////////////////////

int main(void) {
    // ---- One-time system bring-up ----
    system_init_clocks_and_flash();
    system_init_gpio();
    system_init_timers();
    system_init_spi_and_random();
    system_init_usart_ps2();
    system_start_timers();

    // ---- Main application loop ----
    while (1) {
        update_keyboard_state();        // pull new PS/2 events from ISR
        handle_arrow_key_edges();       // send SPI word on arrow press
        handle_periodic_random_update();// refresh random bits on TIM15
        // delay_millis(TIM16, 10);
    }
}
