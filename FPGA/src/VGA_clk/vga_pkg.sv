// vga_pkg.sv
// James Kaden Cassidy 
// kacassidy@hmce.edu
// 11/8/2025

package vga_pkg;

  // All timing information for a VGA mode
  typedef struct {
    // raw inputs
    int pixel_freq_hz;

    int h_visible;
    int h_front_porch;
    int h_sync_pulse;
    int h_back_porch;
    int h_total;

    int v_visible;
    int v_front_porch;
    int v_sync_pulse;
    int v_back_porch;
    int v_total;

    bit h_sync_active_low;
    bit v_sync_active_low;

    // derived / preprocessed
    int h_sync_start;  // first pixel of HSYNC
    int h_sync_end;    // first pixel AFTER HSYNC
    int v_sync_start;  // first line of VSYNC
    int v_sync_end;    // first line AFTER VSYNC

    int h_ctr_bits;    // width needed for horizontal counter
    int v_ctr_bits;    // width needed for vertical counter

    int pixels_x;
    int pixels_y;

  } vga_params_t;


  // Constant function to build the struct so we don't repeat math
  function vga_params_t make_vga_timing(
    int pixel_freq_hz,
    int h_visible, int h_front, int h_sync, int h_back,
    int v_visible, int v_front, int v_sync, int v_back,
    bit h_active_low, bit v_active_low
  );
    vga_params_t t;

    // raw
    t.pixel_freq_hz   = pixel_freq_hz;

    t.h_visible       = h_visible;
    t.h_front_porch   = h_front;
    t.h_sync_pulse    = h_sync;
    t.h_back_porch    = h_back;
    t.h_total         = h_visible + h_front + h_sync + h_back;

    t.v_visible       = v_visible;
    t.v_front_porch   = v_front;
    t.v_sync_pulse    = v_sync;
    t.v_back_porch    = v_back;
    t.v_total         = v_visible + v_front + v_sync + v_back;

    t.h_sync_active_low = h_active_low;
    t.v_sync_active_low = v_active_low;

    // derived
    t.h_sync_start    = h_visible + h_front;
    t.h_sync_end      = t.h_sync_start + h_sync;

    t.v_sync_start    = v_visible + v_front;
    t.v_sync_end      = t.v_sync_start + v_sync;

    t.h_ctr_bits      = $clog2(t.h_total);
    t.v_ctr_bits      = $clog2(t.v_total);

    return t;
  endfunction


  // 640x480 @ 60 Hz from your screenshot
  // pixel clock: 25.175 MHz
  // HSYNC, VSYNC are negative polarity → active low = 1
  localparam vga_params_t VGA_640x480_60 = make_vga_timing(
    25_175_000,
    // H: vis, front, sync, back
    640, 16, 96, 48,
    // V: vis, front, sync, back
    480, 10, 2, 33,
    // polarities
    1'b1, 1'b1
  );

endpackage : vga_pkg
