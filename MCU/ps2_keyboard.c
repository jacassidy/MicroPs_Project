/*
 * ps2_keyboard.c
 * PS/2 keyboard handling and scan-code decoding (Set 2).
 */

#include <stdint.h>
#include <stdio.h>

#include "stm32l4xx.h"
#include "ps2_keyboard.h"
#include "main.h"  // for check_timer / begin_timer / TIM16 etc.

/* ---------------- Keyboard state and PS/2 mailbox ---------------- */

#define KB_MAX_KEYS 128

// Latched state: 1 = this ASCII key has been pressed (per current logic)
static volatile uint8_t g_keyboard_state[KB_MAX_KEYS] = {0};

// Mailbox for one completed PS/2 event assembled by the ISR
static volatile uint8_t g_ps2_req[3];
static volatile uint8_t g_ps2_len         = 0;
static volatile uint8_t g_ps2_event_ready = 0;

// Debug counter used in keyboard_update_state()
static int g_press_count = 0;

/* ---------------- Scan-code decoding (Set 2 -> printable char) ---------------- */

// Decode a single make-code sequence in Scan Code Set 2.
// request[] holds either:
//   [code]              (len = 1)        e.g. 0x1C for 'A'
//   [0xE0, code]        (len = 2)        e.g. 0xE0 0x75 for Up Arrow
// We ignore break codes (anything with F0) before calling this.
// Returns 0 if we don't know how to print it.
static char decode_scancode(const uint8_t *request, int len) {
    uint8_t code = request[len - 1];  // last byte is the make code

    // Handle a few extended keys:
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

/* ---------------- Public keyboard API ---------------- */

// Update global keyboard state based on the latest make-code in `request`.
// Only called when we've established a *make* (key press), never on breaks.
// request / req_len come from scanKeyboard().
// Handles normal + extended, make + break.
// Formats we expect:
//
//   Make (normal):        [code]
//   Make (extended):      [0xE0, code]
//   Break (normal):       [0xF0, code]
//   Break (extended):     [0xE0, 0xF0, code]
//
// We convert these into a "make-style" temp buffer for decode_scancode()
// and then set g_keyboard_state[ch] = 1 (press) or 0 (release).
void keyboard_update_state(const uint8_t *request, int req_len) {
    if (req_len <= 0) {
        return;
    }

    uint8_t is_break = 0;
    uint8_t temp[2];
    int     tlen = 0;

    // --------- Classify the event & build a temp buffer ---------
    if (req_len == 1) {
        // Simple make: [code]
        is_break = 0;
        temp[0]  = request[0];
        tlen     = 1;
    } else if (req_len == 2) {
        if (request[0] == 0xE0) {
            // Extended make: [0xE0, code]
            is_break = 0;
            temp[0]  = 0xE0;
            temp[1]  = request[1];
            tlen     = 2;
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
        // Extended break: [0xE0, 0xF0, code]
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

    // --------- Map to a printable "key" using decoder ---------
    char ch = decode_scancode(temp, tlen);
    if (ch == 0) {
        return;  // unmapped key, ignore
    }

    unsigned char idx = (unsigned char) ch;
    if (idx >= KB_MAX_KEYS) {
        return;
    }

    // --------- Update global pressed/released state ---------
    if (is_break) {
        g_keyboard_state[idx] = 0;
    } else {
        if (check_timer(TIM16)) {
            g_keyboard_state[idx] = 1;
            printf("press \n %d", g_press_count);
            g_press_count++;
            begin_timer(TIM16, 100);
        } else {
            g_keyboard_state[idx] = 0;
        }
    }
}

// Getter you can call from main loop: non-zero if this key is pressed.
uint8_t keyboard_get_key_state(char key) {
    unsigned char idx = (unsigned char) key;
    if (idx < KB_MAX_KEYS) {
        return g_keyboard_state[idx];
    }
    return 0;
}

// Pull a new event from the ISR mailbox (if any) and feed it into
// keyboard_update_state().
void scanKeyboard(void) {
    // If no new event from ISR, nothing to do
    if (!g_ps2_event_ready) {
        return;
    }

    uint8_t local_req[3];
    uint8_t local_len;

    // Critical section: copy the mailbox and clear the flag
    __disable_irq();
    local_len = g_ps2_len;
    for (uint8_t i = 0; i < local_len; i++) {
        local_req[i] = g_ps2_req[i];
    }
    g_ps2_event_ready = 0;
    __enable_irq();

    // Now decode and update keyboard state outside the ISR
    keyboard_update_state(local_req, local_len);
}

/* ---------------- USART1 ISR (PS/2 byte assembler) ---------------- */
// Interrupt handler that assembles PS/2 Scan Code
// Set up to 3 events into a small global mailbox (g_ps2) consumed by scanKeyboard().
// includes global mailbox variables ps2_req, ps2_len, ps2_event_ready.
void USART1_IRQHandler(void) {
    // Read status and data if RXNE is set
    if (USART1->ISR & USART_ISR_RXNE) {
        uint8_t b = (uint8_t) USART1->RDR;  // reading RDR clears RXNE

        // Simple state machine to assemble Scan Code Set 2 sequences
        static uint8_t acc[3];
        static uint8_t acc_len = 0;

        if (acc_len == 0) {
            acc[0]  = b;
            acc_len = 1;

            // Simple 1-byte make (no prefix)
            if (b != 0xE0 && b != 0xF0) {
                if (!g_ps2_event_ready) {
                    g_ps2_req[0]      = b;
                    g_ps2_len         = 1;
                    g_ps2_event_ready = 1;
                }
                acc_len = 0;
            }
        } else if (acc_len == 1) {
            acc[1]  = b;
            acc_len = 2;

            if (acc[0] == 0xE0) {
                // [0xE0, code] extended make OR [0xE0, 0xF0] extended break prefix
                if (b == 0xF0) {
                    // Extended break prefix, need one more byte
                    // keep acc_len = 2
                } else {
                    // Extended make: [0xE0, code]
                    if (!g_ps2_event_ready) {
                        g_ps2_req[0]      = 0xE0;
                        g_ps2_req[1]      = b;
                        g_ps2_len         = 2;
                        g_ps2_event_ready = 1;
                    }
                    acc_len = 0;
                }
            } else if (acc[0] == 0xF0) {
                // Normal break: [0xF0, code]
                if (!g_ps2_event_ready) {
                    g_ps2_req[0]      = 0xF0;
                    g_ps2_req[1]      = b;
                    g_ps2_len         = 2;
                    g_ps2_event_ready = 1;
                }
                acc_len = 0;
            } else {
                // Unexpected, treat second byte as standalone
                if (!g_ps2_event_ready) {
                    g_ps2_req[0]      = b;
                    g_ps2_len         = 1;
                    g_ps2_event_ready = 1;
                }
                acc_len = 0;
            }
        } else if (acc_len == 2) {
            acc[2] = b;

            // Extended break: [0xE0, 0xF0, code]
            if (acc[0] == 0xE0 && acc[1] == 0xF0) {
                if (!g_ps2_event_ready) {
                    g_ps2_req[0]      = 0xE0;
                    g_ps2_req[1]      = 0xF0;
                    g_ps2_req[2]      = b;
                    g_ps2_len         = 3;
                    g_ps2_event_ready = 1;
                }
            }

            // Done
            acc_len = 0;
        }
    }
}
