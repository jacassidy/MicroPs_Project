MicroPs Project — FPGA Tetris System

This repository contains the complete hardware and firmware implementation of our FPGA-based Tetris system, created for the Microprocessors final project. The design integrates a custom FPGA video pipeline, a microcontroller interface, hardware PLLs, SPI-based communication, and game logic implemented entirely in SystemVerilog.

Repository Structure
MicroPs_Project/
├── fpga/                 # SystemVerilog source files for FPGA design
│   ├── top_debug.sv      # Top-level module for the FPGA system
│   ├── vga/              # VGA timing, pixel pipeline, rendering modules
│   ├── tetris/           # Game logic, piece rotation, board updates
│   ├── spi/              # SPI interface for MCU-FPGA communication
│   ├── pll/              # Hardware PLL modules and clocking resources
│   └── testbenches/      # Testbenches for major modules
│
├── mcu/                  # Microcontroller firmware for interfacing with FPGA
│   ├── src/              # Core MCU source code
│   └── include/          # Header files used by the MCU project
│
├── docs/                 # Documentation, diagrams, Quarto pages, project report
│   └── portfolio.qmd     # Final project website content
│
├── assets/               # Images, diagrams, block schematics used in docs
│
└── README.md             # This file

Project Overview

The system implements a complete hardware Tetris game with:

Custom VGA pipeline generating 640×480 @ 60 Hz

Hardware PLL to produce the precise pixel clock

Tetris game logic implemented in pure SystemVerilog (board state, piece movement, collision, rotation, line clearing)

SPI-based communication between MCU and FPGA

PS/2 keyboard input processed by the FPGA for player controls

Deterministic hardware random generator sourced from the MCU

Debug and telemetry modules for real-time visualization of internal FPGA state

Key Components
FPGA System (SystemVerilog)

Located in fpga/.

VGA modules handle timing, visible-region generation, and pixel output.

Tetris logic controls piece spawning, rotation, collision detection, and line clearing.

Active piece blitting overlays the falling piece into the board matrix.

PLL module generates the exact pixel clock required for stable VGA output.

SPI interface receives random numbers and control updates from the MCU.

Telemetry renderer displays debug data on-screen for development and testing.

Microcontroller (MCU) Firmware

Located in mcu/.

Sends random values and control signals to FPGA.

Receives game state or debug info when needed.

Performs final cleanup, error checking, and data packaging.

Documentation

Located in docs/.

portfolio.qmd is the Quarto webpage describing the system architecture, bill of materials, FPGA/MCU design summaries, results, references, and acknowledgements.

How to Build and Run
FPGA

Open the project using Lattice Radiant or the provided build files.

Synthesize the design.

Program the iCE40 UltraPlus FPGA board.

Connect VGA display and PS/2 keyboard.

Run MCU firmware to send startup data.

MCU

Open mcu/ in your preferred embedded environment.

Compile and flash the code to the microcontroller board.

Connect SPI pins to the FPGA.

Requirements

Lattice iCE40 UltraPlus FPGA

Compatible MCU (HMC MicroPs course board)

VGA display

PS/2 keyboard

Radiant toolchain

Standard hardware lab peripherals

Contributors

James Kaden Cassidy

Team Members: (Add remaining team names and bios here)

License

This project is for educational use within the Microprocessors course at Harvey Mudd College. Redistribution should include proper credit.
