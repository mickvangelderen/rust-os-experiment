#![feature(lang_items)]
#![feature(unique)]
#![feature(const_fn)]
#![no_std]

// Implement libc in rust.
extern crate rlibc;
mod vga_buffer;

fn print_something() {
  use vga_buffer::Writer;
  use vga_buffer::ColorCode;
  use vga_buffer::Color;
  use core::ptr::Unique;

  let mut writer = Writer::new(
    unsafe { Unique::new(0xb8000 as *mut _) }
  );

  writer.write_byte(b'H');
}

#[no_mangle]
pub extern fn rust_main() {
  // NOTE: We have a very small stack and no guard page.
  print_something();

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
