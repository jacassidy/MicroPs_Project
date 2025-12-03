/*
 * spi_protocol.c
 * Random-field management + SPI word packing and parity.
 */

#include <stdint.h>

#include "STM32L432KC_SPI.h"
#include "random.h"
#include "stm32l4xx.h"
#include "spi_protocol.h"

// 3-bit random value used in the SPI payload (0..6).
static volatile uint8_t g_random3 = 0;

// Compute even parity of an 8-bit value.
static uint8_t compute_parity(uint8_t x) {
    uint8_t p = 0;
    for (int i = 0; i < 8; ++i) {
        p ^= (x & 0x01);
        x >>= 1;
    }
    return p;  // 0 if even # of 1s, 1 if odd # of 1s
}

void update_random3(void) {
    uint32_t r;
    uint8_t  v;

    do {
        r = getRandomNumber();
        v = r & 0x07;
    } while (v == 7);    // avoid 7

    g_random3 = v;
}

void send_spi_word(uint8_t key_pressed, uint8_t key_value) {
    // First build the payload (no parity yet)
    uint8_t payload =
        (uint8_t)( ((key_pressed & 0x01) << 5) |   // bit 5
                   (( g_random3  & 0x07) << 2) |   // bits 4..2
                   ( key_value   & 0x03) );        // bits 1..0

    // Compute even parity over the payload bits
    uint8_t parity_bit = compute_parity(payload);  // 0 or 1

    // Put parity in MSB (bit 7). bit 6 stays 0.
    uint8_t word = (uint8_t)((parity_bit << 7) | payload);

    enable_cs();
    spiSendReceive(word);   // 0xFF & word is redundant here
    disable_cs();
}
