// STM32L432KC_GPIO.h
// Header for GPIO functions

#ifndef STM32L4_GPIO_H
#define STM32L4_GPIO_H

#include <stdint.h> // Include stdint header
#include <stm32l432xx.h>

///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////
// Set bit 'b' in variable 'x'
#define SET_BIT(x, b)   ((x) |= (1U << (b)))

// Clear bit 'b' in variable 'x'
#define CLEAR_BIT(x, b) ((x) &= ~(1U << (b)))

// Toggle bit 'b' in variable 'x'
#define TOGGLE_BIT(x, b) ((x) ^= (1U << (b)))

// Read bit 'b' in variable 'x' (returns 0 or 1)
#define READ_BIT(x, b)  (((x) >> (b)) & 1U)


// Values which "val" can take on in digitalWrite()
#define PIO_LOW  0 // Value to write a pin low (0 V)
#define PIO_HIGH 1 // Value to write a pin high (3.3 V)

// Arbitrary port IDs used to easily find a pin's port
#define GPIO_PORT_A 0 // Arbitrary ID for GPIO Port A
#define GPIO_PORT_B 1 // Arbitrary ID for GPIO Port B
#define GPIO_PORT_C 2 // Arbitrary ID for GPIO Port C

// Arbitrary GPIO functions for pinMode()
#define GPIO_INPUT  0
#define GPIO_OUTPUT 1
#define GPIO_ALT    2
#define GPIO_ANALOG 3

// Values which "setting" can take on in pinResistor()
#define GPIO_PULL_UP   0 // Arbitrary ID for a pull-up resistor
#define GPIO_PULL_DOWN 1 // Arbitrary ID for a pull-down resistor
#define GPIO_FLOATING  2 // Arbitrary ID for a floating pin (neither resistor is active)

#define GPIOA2_BASE  (0x48000000UL)

// Pin definitions for every GPIO pin
#define PA0    0
#define PA1    1
#define PA2    2
#define PA3    3
#define PA4    4
#define PA5    5
#define PA6    6
#define PA7    7
#define PA8    8
#define PA9    9
#define PA10   10
#define PA11   11
#define PA12   12
#define PA13   13
#define PA14   14
#define PA15   15
#define PB0    16
#define PB1    17
#define PB2    18
#define PB3    19
#define PB4    20
#define PB5    21
#define PB6    22
#define PB7    23
#define PB8    24
#define PB9    25
#define PB10   26
#define PB11   27
#define PB12   28
#define PB13   29
#define PB14   30
#define PB15   31
#define PC0    32
#define PC1    33
#define PC2    34
#define PC3    35
#define PC4    36
#define PC5    37
#define PC6    38
#define PC7    39
#define PC8    40
#define PC9    41
#define PC10   42
#define PC11   43
#define PC12   44
#define PC13   45
#define PC14   46
#define PC15   47

// GPIO register structs here
typedef struct {
    volatile uint32_t MODER;   // GPIO Offset 0x00 GPIO port mode register
    volatile uint32_t OTYPER;  // GPIO Offset 0x04
    volatile uint32_t OSPEEDR; // GPIO Offset 0x08
    volatile uint32_t PURPDR;  // GPIO Offset 0x0C
    volatile uint32_t IDR;     // GPIO Offset 0x10
    volatile uint32_t ODR;     // GPIO Offset 0x14
    volatile uint32_t BSRR;    // GPIO Offset 0x18
    volatile uint32_t LCKR;    // GPIO Offset 0x1C
    volatile uint32_t AFRL;    // GPIO Offset 0x20
    volatile uint32_t AFRH;    // GPIO Offset 0x24
} GPIO;

// Pointers to GPIO-sized chunks of memory for each peripheral
#define GPIOA2 ((GPIO *) GPIOA_BASE)

#define GPIO GPIOA2

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void gpioEnable(int port_id);

int gpioPinOffset(int gpio_pin);

int gpioPinToPort(int gpio_pin);

GPIO_TypeDef * gpioPortToBase(int port);

GPIO_TypeDef * gpioPinToBase(int gpio_pin);

void pinResistor(int pin, int setting);

void pinMode(int gpio_pin, int function);

int digitalRead(int gpio_pin);

void digitalWrite(int gpio_pin, int val);

void togglePin(int gpio_pin);

#endif