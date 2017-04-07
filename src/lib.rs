#![feature(lang_items)]
#![no_std]

// Implement libc in rust.
extern crate rlibc;

#[no_mangle]
pub extern fn rust_main() {
  // NOTE: We have a very small stack and no guard page.
  let hello = b"Hello World!";
  let color_byte: u8 = 0x1f;

  let mut hello_colored = [color_byte; 12*2];
  for (i, char_byte) in hello.into_iter().enumerate() {
    hello_colored[i*2] = *char_byte;
  }

  let vga_buffer = (0xb8000) as *mut _;
  unsafe { *vga_buffer = hello_colored };

  loop {}
}

/// Dummy implementation of _Unwind_Resume. It is called when the stack
/// unwinds which is done to recover from panics. We don't care at the
/// moment and just want to abort.
#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
  loop {}
}

#[lang = "eh_personality"]
extern fn eh_personality() {}

#[lang = "panic_fmt"]
#[no_mangle]
pub extern fn panic_fmt() -> ! {loop{}}
