#!/usr/bin/env python3
"""
fix_tls_align.py — Parchea la alineación del segmento PT_TLS en un ELF ARM64.
Bionic lee el p_align del program header, no el sh_addralign del section header.

Uso: python3 fix_tls_align.py <binario>
"""

import struct
import sys

def fix_tls_alignment(path, required_align=64):
    with open(path, "r+b") as f:
        data = bytearray(f.read())

    # Verificar magic ELF
    if data[:4] != b'\x7fELF':
        print("ERROR: no es un ELF válido")
        sys.exit(1)

    ei_class = data[4]  # 2 = 64-bit
    ei_data  = data[5]  # 1 = little-endian, 2 = big-endian
    endian   = "<" if ei_data == 1 else ">"

    if ei_class != 2:
        print("ERROR: solo soporta ELF 64-bit")
        sys.exit(1)

    # ELF header fields (64-bit)
    e_phoff   = struct.unpack_from(endian + "Q", data, 0x20)[0]  # offset tabla program headers
    e_phentsize = struct.unpack_from(endian + "H", data, 0x36)[0]
    e_phnum     = struct.unpack_from(endian + "H", data, 0x38)[0]

    print(f"Program headers: {e_phnum} entradas @ offset 0x{e_phoff:x}, tamaño {e_phentsize} bytes")

    # PT_TLS = 7
    PT_TLS = 7
    patched = 0

    for i in range(e_phnum):
        ph_offset = e_phoff + i * e_phentsize
        p_type = struct.unpack_from(endian + "I", data, ph_offset)[0]

        if p_type == PT_TLS:
            # Elf64_Phdr layout:
            # 0x00 p_type   (4)
            # 0x04 p_flags  (4)
            # 0x08 p_offset (8)
            # 0x10 p_vaddr  (8)
            # 0x18 p_paddr  (8)
            # 0x20 p_filesz (8)
            # 0x28 p_memsz  (8)
            # 0x30 p_align  (8)  ← este es el que lee Bionic
            p_align_offset = ph_offset + 0x30
            p_align = struct.unpack_from(endian + "Q", data, p_align_offset)[0]
            print(f"PT_TLS [#{i}]: p_align actual = {p_align} (0x{p_align:x})")

            if p_align < required_align:
                struct.pack_into(endian + "Q", data, p_align_offset, required_align)
                new_val = struct.unpack_from(endian + "Q", data, p_align_offset)[0]
                print(f"PT_TLS [#{i}]: p_align parcheado → {new_val} (0x{new_val:x}) ✓")
                patched += 1
            else:
                print(f"PT_TLS [#{i}]: ya alineado correctamente, sin cambios")

    if patched == 0 and p_type != PT_TLS:
        print("ADVERTENCIA: no se encontró segmento PT_TLS en el binario")
        sys.exit(1)

    with open(path, "wb") as f:
        f.write(data)

    print(f"\nOK: {path} parcheado ({patched} segmento(s) modificado(s))")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Uso: {sys.argv[0]} <binario_elf>")
        sys.exit(1)
    fix_tls_alignment(sys.argv[1])
