#ifndef SPI_PROTOCOL_H
#define SPI_PROTOCOL_H

#include <stdint.h>

/**
 * Update the 3-bit random value used in the SPI word.
 * Keeps the value in an internal module-global.
 */
void update_random3(void);

/**
 * Pack a SPI word with:
 *   bit 7 : even parity over bits 6..0
 *   bit 6 : 0
 *   bit 5 : key_pressed (0/1)
 *   bits 4..2 : 3-bit random value (0..6)
 *   bits 1..0 : key_value (0..3 encoding ^ v < >)
 */
void send_spi_word(uint8_t key_pressed, uint8_t key_value);

#endif // SPI_PROTOCOL_H
