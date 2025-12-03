flowchart LR
  %% Top-level module
  subgraph top_debug
    direction LR

    EXTIO["External I/O\n(reset_n, sck, sdi, ce, external_clk_raw,\n h_sync, v_sync, pixel_signal_R/G/B, sdo, debug_led)"]

    VGA["vga_controller\n(VGA_Controller)"]
    SM["state_manager\n(State_Manager)"]
    DEC["game_decoder\n(Game_Decoder)"]
    GX["game_executioner\n(Game_Executioner)"]
    SPIblk["spi\n(SPI)"]
    CLKDIV["clock_divider\n(Clock_Divider)"]
    SYNCs["synchronizer\n(instances)"]

  end

  %% High-level connections
  EXTIO --> VGA
  EXTIO --> SPIblk

  GX --> SM
  SM --> DEC
  DEC --> VGA

  SPIblk --> GX

  CLKDIV --> GX
  CLKDIV --> EXTIO

  GX --> DEC
  GX --> SYNCs
  SPIblk --> SYNCs
  EXTIO --> SYNCs
