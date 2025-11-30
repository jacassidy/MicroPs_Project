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

/////////////////////////////////////////////////////////////////
// Scan code decoding (Set 2 -> printable char)
/////////////////////////////////////////////////////////////////

// Decode a single make-code sequence in Scan Code Set 2.
// request[] holds either:
//   [code]              (len = 1)        e.g. 0x1C for 'A'
//   [0xE0, code]        (len = 2)        e.g. 0xE0 0x75 for Up Arrow
// We ignore break codes (anything with F0) before calling this.
// Returns 0 if we don't know how to print it.
static char decode_scancode(const uint8_t *request, int len) {
    uint8_t code = request[len - 1];  // last byte is the make code

    // Handle a few extended keys if you want:
    if (len == 2 && request[0] == 0xE0) {
        switch (code) {
            case 0x75: return '^';  // Up arrow (placeholder)
            case 0x72: return 'v';  // Down arrow
            case 0x6B: return '<';  // Left arrow
            case 0x74: return '>';  // Right arrow
            default: break;
        }
    }

    // Printable ASCII-ish keys (letters, digits, punctuation, space)
    switch (code) {
        // Row: ` 1 2 3 4 5 6 7 8 9 0 - =
        case 0x0E: return '`';
        case 0x16: return '1';
        case 0x1E: return '2';
        case 0x26: return '3';
        case 0x25: return '4';
        case 0x2E: return '5';
        case 0x36: return '6';
        case 0x3D: return '7';
        case 0x3E: return '8';
        case 0x46: return '9';
        case 0x45: return '0';
        case 0x4E: return '-';
        case 0x55: return '=';

        // Row: Q W E R T Y U I O P [ ]
        case 0x15: return 'Q';
        case 0x1D: return 'W';
        case 0x24: return 'E';
        case 0x2D: return 'R';
        case 0x2C: return 'T';
        case 0x35: return 'Y';
        case 0x3C: return 'U';
        case 0x43: return 'I';
        case 0x44: return 'O';
        case 0x4D: return 'P';
        case 0x54: return '[';
        case 0x5B: return ']';

        // Row: A S D F G H J K L ; ' \
        case 0x1C: return 'A';
        case 0x1B: return 'S';
        case 0x23: return 'D';
        case 0x2B: return 'F';
        case 0x34: return 'G';
        case 0x33: return 'H';
        case 0x3B: return 'J';
        case 0x42: return 'K';
        case 0x4B: return 'L';
        case 0x4C: return ';';
        case 0x52: return '\'';
        case 0x5D: return '\\';

        // Row: Z X C V B N M , . /
        case 0x1A: return 'Z';
        case 0x22: return 'X';
        case 0x21: return 'C';
        case 0x2A: return 'V';
        case 0x32: return 'B';
        case 0x31: return 'N';
        case 0x3A: return 'M';
        case 0x41: return ',';
        case 0x49: return '.';
        case 0x4A: return '/';

        // Space and control-ish keys mapped to common chars
        case 0x29: return ' ';   // Space
        case 0x5A: return '\n';  // Enter
        case 0x0D: return '\t';  // Tab
        case 0x66: return '\b';  // Backspace
        case 0x76: return 27;    // ESC

        default:
            return 0; // Unknown / not mapped
    }
}

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

    int counter = 0;

    // Buffer for a single key event (max 3 bytes, but we only use 1–2 here)
    uint8_t request[3];
    int     req_len = 0;

    while (1) {
        // Check if we have a new byte from the keyboard
        if (USART->ISR & USART_ISR_RXNE) {
            uint8_t b0 = (uint8_t) readChar(USART);

            // ------------------------------------------------------------
            // Handle Scan Code Set 2 prefix rules based on Technoblogy:
            //  - 0xF0 prefix = break (key released)
            //  - 0xE0 prefix = extended key
            //  We only want "make" codes (key pressed) to print.
            // ------------------------------------------------------------

            if (b0 == 0xF0) {
                // Simple break for a 1-byte make code: read and ignore the next byte.
                while (!(USART->ISR & USART_ISR_RXNE));
                (void) readChar(USART);
                continue; // don't print anything for key release
            }

            if (b0 == 0xE0) {
                // Extended key; read next byte
                while (!(USART->ISR & USART_ISR_RXNE));
                uint8_t b1 = (uint8_t) readChar(USART);

                if (b1 == 0xF0) {
                    // Extended break: E0 F0 <code> -> read and ignore <code>
                    while (!(USART->ISR & USART_ISR_RXNE));
                    (void) readChar(USART);
                    continue;
                } else {
                    // Extended make: E0 <code>
                    request[0] = 0xE0;
                    request[1] = b1;
                    req_len    = 2;
                }
            } else {
                // Normal 1-byte make code
                request[0] = b0;
                req_len    = 1;
            }

            // Decode and print
            char key = decode_scancode(request, req_len);
            if (key != 0) {
                if (key == '\n') {
                    printf("Key pressed: [ENTER]\r\n");
                } else if (key == '\t') {
                    printf("Key pressed: [TAB]\r\n");
                } else if (key == '\b') {
                    printf("Key pressed: [BKSP]\r\n");
                } else if (key == 27) {
                    printf("Key pressed: [ESC]\r\n");
                } else {
                    printf("Key pressed: %c\r\n", key);
                }
            } else {
                // Unknown / unmapped scancode
                if (req_len == 1) {
                    printf("Key pressed: [unknown 0x%02X]\r\n", request[0]);
                } else {
                    printf("Key pressed: [unknown 0x%02X 0x%02X]\r\n",
                           request[0], request[1]);
                }
            }
        }


    // // Update string with current LED state
    // counter += 1;
    // uint32_t randnum = getRandomNumber();
    // //printf("%d",randnum);
    // enable_cs();
    // spiSendReceive(randnum & 0xFF);
    // disable_cs();
    // //delay_millis(TIM15, 5000);
    }
}
