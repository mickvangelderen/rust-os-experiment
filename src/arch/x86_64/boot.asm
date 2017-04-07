global start

section .text
bits 32
start:
  ; initialize stack pointer
  mov esp, stack_top

  call check_multiboot
  call check_cpuid
  call check_long_mode

  call set_up_page_tables
  call enable_paging

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

set_up_page_tables:
  ; Make first entry of P4 point to first entry of P3.
  mov eax, p3_table
  ; Toggle present and writable bits.
  or eax, 0b11
  ; Write EAX to *P4
  mov [p4_table], eax

  ; Make first entry of P3 point to first entry of P2.
  mov eax, p2_table
  ; Toggle present and writable bits.
  or eax, 0b11
  ; Write EAX to *P4
  mov [p3_table], eax

  ; Use ecx as the loop index.
  mov ecx, 0
.map_p2_table:
  ; Set EAX to 2MiB (2*1024*1024).
  mov eax, ((2 << 10) << 10)
  ; Multiply by the index.
  mul ecx
  ; Set present, writable and huge flags.
  or eax, 0b10000011
  ; Save at ((int64 *)P2)[ecx].
  mov [p2_table + ecx*8], eax

  ; Loop if ++ecx != 512.
  inc ecx
  cmp ecx, 512
  jne .map_p2_table

  ret

enable_paging:
  ; Store P4 in the CR3 register.
  ; TODO: Is it really necessary to load p4_table into eax before
  ; loading eax into cr3?
  mov eax, p4_table
  mov cr3, eax

  ; Enable PAE-flag in cr4 (Physical Address Extension).
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; Set the long mode flag in the EFER Model Specific Register.
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; Set paging bit in the cr0 register.
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax

  ret

section .bss
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
stack_bottom:
  resb 64
stack_top:
