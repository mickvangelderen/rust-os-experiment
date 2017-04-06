global start

  section .text
  bits 32
start:
  ; initialize stack pointer
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

  ; print "OK" to screen
  mov dword [0xb8000], 0x2f4b2f4f
  hlt

; Prinst "ERR: " and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
  mov dword [0xb8000], 0x4f524f45
  mov dword [0xb8004], 0x4f3a4f52
  mov dword [0xb8008], 0x4f204f20
  mov byte [0xb800a], al
  hlt

check_multiboot:
  cmp eax, 0x36d76289
  jne .no_multiboot
  ret
.no_multiboot:
  mov al, "0"
  jmp error

check_cpuid:
  ; Check if CPUID is supported by attempting to flip the ID bit (bit
  ; 21) in the FLAGS register. If we can flip it, CPUID is available.

  ; Save FLAGS on the stack.
  pushfd

  ; Copy FLAGS into EAX via stack.
  pushfd
  pop eax

  ; Store a second copy of FLAGS in ECX for comparison later on.
  mov ecx, eax

  ; Flip the ID bit
  xor eax, 1 << 21

  ; Copy EAX to FLAGS via the stack. The CPUID flag will only be saved if
  ; CPUID is supported.
  push eax
  popfd

  ; Copy FLAGS back to EAX.
  pushfd
  pop eax

  ; Restore FLAGS from the stack.
  popfd

  ; Compare EAX and ECX. If they are equal then that means the bit
  ; wasn't flipped, and CPUID isn't supported.
  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "1"
  jmp error

check_long_mode:
  ; Test if extended processor info is available.

  ; Implicit argument for cpuid.
  mov eax, 0x80000000
  ; Get highest supported argument.
  cpuid
  ; It needs to be at least 0x80000001.
  cmp eax, 0x80000001
  ; If it is less, the CPU does not support long mode.
  jb .no_long_mode

  ; Use extended info to test if long mode is available.

  ; Argument for extended processor info.
  mov eax, 0x80000001
  ; Returns various feature bits in ecx and edx.
  cpuid
  ; Test if the LM-bit is set in the D-register.
  test edx, 1 << 29
  ; If it is not set, the CPU does not support long mode.
  jz .no_long_mode

  ret
.no_long_mode:
  mov al, "2"
  jmp error

  section .bss
stack_bottom:
  resb 64
stack_top:
