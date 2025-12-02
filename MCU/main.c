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

//// ---- Global variables ---- ////

// Latched state: 1 = this ASCII key has been pressed at least once
// (you can change semantics later if you want edge-triggered behavior)
#define KB_MAX_KEYS 128
volatile uint8_t g_keyboard_state[KB_MAX_KEYS] = {0};

USART_TypeDef * USART;
// Buffer for a single key event (max 3 bytes, but we only use 1–2 here)
uint8_t request[3];

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

// outdated
//
//
//void printKey(uint8_t request[3], int req_len){
//  // Decode and print
//    char key = decode_scancode(request, req_len);
//    if (key != 0) {
//        if (key == '\n') {
//            printf("Key pressed: [ENTER]\r\n");
//        } else if (key == '\t') {
//            printf("Key pressed: [TAB]\r\n");
//        } else if (key == '\b') {
//            printf("Key pressed: [BKSP]\r\n");
//        } else if (key == 27) {
//            printf("Key pressed: [ESC]\r\n");
//        } else {
//            printf("Key pressed: %c\r\n", key);
//        }
//    } else {
//        // Unknown / unmapped scancode
//        if (req_len == 1) {
//            printf("Key pressed: [unknown 0x%02X]\r\n", request[0]);
//        } else {
//            printf("Key pressed: [unknown 0x%02X 0x%02X]\r\n",
//                   request[0], request[1]);
//        }
//    }
//  }

// Update global keyboard state based on the latest make-code in `request`.
// Only called when we've established a *make* (key press), never on breaks.
// request / req_len come from scanKeyboard().
// Handles normal + extended, make + break.
// Formats we expect:
//
//   Make (normal):        [code]
//   Make (extended):      [0xE0, code]
//   Break (normal):       [0xF0, code]
//   Break (extended):     [0xE0, 0xF0, code]   (if you add that case)
//
// We convert these into a "make-style" temp buffer for decode_scancode()
// and then set g_keyboard_state[ch] = 1 (press) or 0 (release).
void keyboard_update_state(const uint8_t *request, int req_len) {
    if (req_len <= 0) return;

    uint8_t is_break = 0;
    uint8_t temp[2];
    int     tlen = 0;

    // --------- Classify the event & build a temp buffer ---------

    if (req_len == 1) {
        // Simple make: [code]
        is_break = 0;
        temp[0] = request[0];
        tlen    = 1;

    } else if (req_len == 2) {
        if (request[0] == 0xE0) {
            // Extended make: [0xE0, code]
            is_break = 0;
            temp[0] = 0xE0;
            temp[1] = request[1];
            tlen    = 2;
        } else if (request[0] == 0xF0) {
            // Normal break: [0xF0, code]
            is_break = 1;
            temp[0]  = request[1];  // decode like a normal 1-byte make
            tlen     = 1;
        } else {
            // Fallback: treat as make of last byte
            is_break = 0;
            temp[0]  = request[req_len - 1];
            tlen     = 1;
        }

    } else if (req_len == 3) {
        // Extended break: [0xE0, 0xF0, code]  (if you implement this pattern)
        if (request[0] == 0xE0 && request[1] == 0xF0) {
            is_break = 1;
            temp[0]  = 0xE0;
            temp[1]  = request[2];
            tlen     = 2;
        } else {
            // Fallback: best effort – treat last as simple code
            is_break = 0;
            temp[0]  = request[req_len - 1];
            tlen     = 1;
        }
    } else {
        // Unexpected length, best-effort decode last byte
        is_break = 0;
        temp[0]  = request[req_len - 1];
        tlen     = 1;
    }

    // --------- Map to a printable "key" using your existing decoder ---------
    char ch = decode_scancode(temp, tlen);
    if (ch == 0) return;  // unmapped key, ignore

    unsigned char idx = (unsigned char) ch;
    if (idx >= KB_MAX_KEYS) return;

    // --------- Update global pressed/released state ---------
    g_keyboard_state[idx] = is_break ? 0 : 1;
}


// Getter you can call from main loop: non-zero if we've ever seen this key.
uint8_t keyboard_get_key_state(char key) {
    unsigned char idx = (unsigned char) key;
    if (idx < KB_MAX_KEYS) {
        return g_keyboard_state[idx];
    }
    return 0;
}

void scanKeyboard(){
  int req_len = 0;
  if (USART->ISR & USART_ISR_RXNE) {
      uint8_t b0 = (uint8_t) readChar(USART);

      // ------------------------------------------------------------
      // Handle Scan Code Set 2 prefix rules based on Technoblogy:
      //  - 0xF0 prefix = break (key released)
      //  - 0xE0 prefix = extended key
      //  We only want "make" codes (key pressed) to print.
      // ------------------------------------------------------------

     char readCharecter = readChar(USART);

      request[req_len++] =  readCharecter;
      if (readCharecter == 0xE0) {
        // extend key singal, get next
        while(!(USART->ISR & USART_ISR_RXNE));
        char readCharecter = readChar(USART);
        request[req_len++] =  readCharecter;
        }
      if (readCharecter == 0xF0) {
        // Release key signal, get next
        while(!(USART->ISR & USART_ISR_RXNE));
        char readCharecter = readChar(USART);
        request[req_len++] =  readCharecter;
      }

      // new key press established

      //printKey(request, req_len);

      keyboard_update_state(request, req_len);
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
    //initTIM(TIM16);
    //delay_millis(TIM15, 1000);

    RCC->APB2ENR |= (1 << 12); // ENABLE SPI1

    configureSPIPins();

    initSPI(0b111, 0, 0);
    //digitalWrite(RESET_N, 1);

    initRandomGenerator();

    USART = initUSART(USART1_ID, 11500);

    int counter = 0;

    begin_timer(TIM15, 1000);

    while (1) {
      // Check if we have a new byte from the keyboard
      scanKeyboard();
      
      if (check_timer(TIM15)){
        int key_value     = 0;
        bool key_pressed  = false;
        if (keyboard_get_key_state('W')) {
          key_value = 0;
          key_pressed = true;
        }else if(keyboard_get_key_state('S')) {
          key_value = 1;
          key_pressed = true;
        }else if(keyboard_get_key_state('A')) {
          key_value = 2;
          key_pressed = true;
        }else if(keyboard_get_key_state('D')) {
          key_value = 3;
          key_pressed = true;
        }

       
        // W has been pressed at least once
        // do something for forward movement, etc.
        printf("W Key down\n");
         // // Update string with current LED state
        // counter += 1;
        uint32_t randnum = getRandomNumber();
        while ((randnum & 0xFF) == 8){
          randnum = getRandomNumber();
        }
        //printf("%d",randnum);
        enable_cs();
        spiSendReceive(0xFF & ((uint8_t)key_pressed << (2 + 3) | ((uint8_t)randnum << 2) | (uint8_t)key_value));
        disable_cs();
      }


      begin_timer(TIM15, 1000);
    }

      //delay_millis(TIM16, 10);
}
