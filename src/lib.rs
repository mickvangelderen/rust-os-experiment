#![feature(lang_items)]
#![no_std]

// Implement libc in rust.
extern crate rlibc;

#[no_mangle]
pub extern fn rust_main() {}
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
