; SimpleOS - 16-bit real mode, 80x25 text, one boot sector, pure NASM
; Commands: help, echo, cls, kill
; Build: nasm -f bin simpleos.asm -o simpleos.img
; Run:   qemu-system-i386 -drive format=raw,file=simpleos.img

bits 16
org 0x7C00

buf equ 0x7E00                  ; input buffer (free RAM after boot sector)

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld
    call cls
    mov si, msg_boot
    call print

main_loop:
    mov si, prompt
    call print
    mov di, buf

.read:
    xor ah, ah
    int 0x16                    ; wait for key -> AL
    cmp al, 13
    je .enter
    cmp al, 8
    je .bs
    cmp al, 32
    jb .read
    cmp di, buf + 78
    jae .read
    stosb
    call putc
    jmp .read

.bs:
    cmp di, buf
    je .read
    dec di
    mov al, 8
    call putc
    mov al, ' '
    call putc
    mov al, 8
    call putc
    jmp .read

.enter:
    xor al, al
    stosb                       ; terminate string
    call newline
    cmp byte [buf], 0
    je main_loop

    mov si, buf
    mov di, s_help
    call cmd_match
    jc do_help
    mov di, s_echo
    call cmd_match
    jc do_echo
    mov di, s_cls
    call cmd_match
    jc do_cls
    mov di, s_kill
    call cmd_match
    jc do_kill

    mov si, msg_unk
    call print
    jmp main_loop

; ---------- commands ----------
do_help:
    mov si, msg_help
    call print
    jmp main_loop

do_echo:                        ; SI already points to the arguments
    call print
    call newline
    jmp main_loop

do_cls:
    call cls
    jmp main_loop

do_kill:
    mov si, msg_bye
    call print
    mov ax, 0x5301              ; APM: connect
    xor bx, bx
    int 0x15
    mov ax, 0x530E              ; APM: set version 1.2
    xor bx, bx
    mov cx, 0x0102
    int 0x15
    mov ax, 0x5307              ; APM: power off all devices
    mov bx, 1
    mov cx, 3
    int 0x15
    mov ax, 0x2000
    mov dx, 0x604               ; QEMU (new ACPI)
    out dx, ax
    mov dx, 0xB004              ; QEMU (old) / Bochs
    out dx, ax
    cli
.halt:
    hlt
    jmp .halt

; ---------- helpers ----------
; in: SI = input, DI = command (0-terminated)
; out: CF=1 match (SI -> args), CF=0 no match (SI unchanged)
cmd_match:
    push si
.l:
    mov al, [di]
    test al, al
    jz .end
    cmp al, [si]
    jne .no
    inc si
    inc di
    jmp .l
.end:
    mov al, [si]
    test al, al
    jz .yes
    cmp al, ' '
    jne .no
    inc si
.yes:
    add sp, 2                   ; drop saved SI, keep advanced one
    stc
    ret
.no:
    pop si
    clc
    ret

cls:
    mov ax, 0x0003              ; set 80x25 text mode (clears screen)
    int 0x10
    ret

print:                          ; SI = 0-terminated string
    lodsb
    test al, al
    jz .done
    call putc
    jmp print
.done:
    ret

putc:                           ; AL = char
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    ret

newline:
    mov al, 13
    call putc
    mov al, 10
    call putc
    ret

; ---------- data ----------
s_help   db "help", 0
s_echo   db "echo", 0
s_cls    db "cls", 0
s_kill   db "kill", 0

msg_boot db "SimpleOS. Type 'help'.", 13, 10, 0
prompt   db "> ", 0
msg_unk  db "Unknown command", 13, 10, 0
msg_bye  db "Shutting down...", 13, 10, 0
msg_help db "help - show all commands", 13, 10
         db "echo - echo your text", 13, 10
         db "cls  - clear screen", 13, 10
         db "kill - shutdown os", 13, 10, 0

times 510 - ($ - $$) db 0
dw 0xAA55
