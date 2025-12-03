#ifndef PS2_KEYBOARD_H
#define PS2_KEYBOARD_H

#include <stdint.h>

/**
 * Update internal keyboard state from a PS/2 scan-code event.
 * Usually you do not call this directly; call scanKeyboard() from main.
 */
void keyboard_update_state(const uint8_t *request, int req_len);

/**
 * Returns non-zero if this key is currently considered "pressed"
 * according to the latched keyboard state.
 */
uint8_t keyboard_get_key_state(char key);

/**
 * Called from main loop to pull a completed PS/2 event out of the
 * ISR mailbox and feed it into keyboard_update_state().
 */
void scanKeyboard(void);

/**
 * USART1 interrupt handler that assembles PS/2 Scan Code Set 2 events
 * into a small mailbox consumed by scanKeyboard().
 * (Name must match the vector table.)
 */
void USART1_IRQHandler(void);

#endif // PS2_KEYBOARD_H
