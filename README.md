# SimpleOS

A minimal 16-bit operating system written entirely in x86 assembly (NASM). It fits in a single 512-byte boot sector and runs in real mode with an 80x25 text display.

## Features

| Command | Description |
|---------|-------------|
| `help`  | Show all commands |
| `echo`  | Print the text you type after it (`echo hello`) |
| `cls`   | Clear the screen |
| `kill`  | Shut down the OS |

Also supported: Backspace editing and an "Unknown command" message for invalid input.

## How it works

- **Boot:** the BIOS loads the boot sector to `0x7C00`. SimpleOS sets up segments and the stack, then clears the screen.
- **Input:** keys are read with BIOS `int 0x16` and stored in a buffer at `0x7E00`.
- **Output:** text is printed with BIOS `int 0x10` (teletype).
- **Commands:** the input line is compared against each command name, and the matching handler runs.
- **Shutdown:** `kill` tries APM (`int 0x15`), then the QEMU/Bochs ACPI ports (`0x604`, `0xB004`), then halts the CPU.

Everything lives in one file, `simpleos.asm`, with no external dependencies.

## Requirements

- [NASM](https://www.nasm.us/)
- [QEMU](https://www.qemu.org/) (or any x86 emulator / real hardware with legacy BIOS boot)

## Build

```
nasm -f bin simpleos.asm -o simpleos.img
```

## Run

```
qemu-system-i386 -drive format=raw,file=simpleos.img
```

Alternative (floppy mode):

```
qemu-system-i386 -fda simpleos.img
```

## Example session

```
SimpleOS. Type 'help'.
> help
help - show all commands
echo - echo your text
cls  - clear screen
kill - shutdown os
> echo Hello, world!
Hello, world!
> kill
Shutting down...
```

## Limitations

- BIOS (legacy) boot only, no UEFI.
- Real mode only: 16-bit, 1 MB address space.
- Input line limited to 78 characters.
- Shutdown depends on emulator/BIOS support; on unsupported systems the CPU is halted instead.

## License

Public domain / do whatever you want.
