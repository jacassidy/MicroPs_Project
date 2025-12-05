
## Project Overview

This system implements a complete Tetris game entirely in hardware using:

- Custom VGA pipeline generating 640×480 @ 60 Hz  
- Hardware PLL to generate the pixel clock  
- Tetris game logic written in SystemVerilog  
- Active piece rotation, collision detection, and line clearing  
- SPI communication between MCU and FPGA  
- PS/2 keyboard input for player controls  
- On-screen debug and telemetry overlay  
- Deterministic hardware random generator sourced from the MCU  

## FPGA Design (SystemVerilog)

Located in `fpga/`.

Key components include:

- VGA timing and pixel pipeline  
- Game board state machine  
- Piece rotation and movement logic  
- Collision detection and bottom-touch logic  
- Line-clear mechanism  
- Active piece blitter  
- PLL for video clock  
- SPI receiver for MCU commands  
- Telemetry renderer for debugging

## Microcontroller Firmware

Located in `mcu/`.

The MCU:

- Sends random numbers and control updates over SPI  
- Handles initialization logic  
- Performs cleanup and validation on outgoing data  
- Interfaces with physical I/O peripherals  

## Documentation

Located in `docs/`.

- `portfolio.qmd` contains the Quarto report/website for the project.  
- Diagrams and reference images are stored in `assets/`.

## How to Build and Run

### FPGA

1. Open the project in **Lattice Radiant**.  
2. Synthesize and implement the design.  
3. Program the iCE40 UltraPlus FPGA.  
4. Connect:
   - VGA monitor  
   - PS/2 keyboard  
   - MCU SPI lines  
5. Run the MCU firmware.

### MCU

1. Open the `mcu/` folder in your preferred embedded environment.  
2. Build and flash firmware to the microcontroller board.  
3. Connect SPI signals (SCK, SDI, SDO, CE) to FPGA.

## Requirements

- Lattice iCE40 UltraPlus FPGA  
- Compatible MCU (HMC MicroPs course board)  
- VGA monitor  
- PS/2 keyboard  
- Lattice Radiant toolchain  
- Standard lab hardware equipment  

## Contributors

- **James Kaden Cassidy**  
- *(Add additional team members and links as needed)*

## License

This project is for educational use. Redistribution should include appropriate credit.
