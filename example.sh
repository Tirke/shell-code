#!/bin/bash
# Script pour obtenir un shellcode
# Thomas Schersach - Arnaud Freismuth
# Cours de sécurité - M2 MIAGE - SID
# janv, 2018

# Installation des librairies necéssaires
yum install -y nasm gcc

# Création du code assembleur
echo "[SECTION .text]

global _start

_start:

        jmp short ender

        starter:

        xor eax, eax    ;clean up the registers
        xor ebx, ebx
        xor edx, edx
        xor ecx, ecx

        mov al, 4       ;syscall write
        mov bl, 1       ;stdout is 1
        pop ecx         ;get the address of the string from the stack
        mov dl, 14      ;length of the string
        int 0x80

        xor eax, eax
        mov al, 1       ;exit the shellcode
        xor ebx,ebx
        int 0x80

        ender:
        call starter  ;put the address of the string on the stack
        db 'Bonjour la SID'" > hello.asm

# Compiler et créer un créer un exécutable (pour 64 bits):
nasm -f elf hello.asm
ld -m elf_i386 -s -o hello hello.o

# Création du code c
echo "char code[] = " > hello.c

objdump -d hello|grep '[0-9a-f]:'|grep -v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\t' ' '|sed 's/ $//g'|sed 's/ /\\x/g'|paste -d '' -s |sed 's/^/"/'|sed 's/$/";/g' >> hello.c

echo "int main(int argc, char **argv)
{
        int (*func)();
        func = (int (*)()) code;
        (int)(*func)();
}" >> hello.c


# Compilation
gcc -fno-stack-protector -z execstack hello.c

# Exécuter
./a.out
