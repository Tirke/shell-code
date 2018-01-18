# Shell code

Réalisation d'un shellcode sur Centos 7 et réalisation d’un payload bind_shell_tcp utilisant un shellcode qui sera exécuté dans un jar (Java).

## Prérequis

Les différentes commandes sont nécessaires :

* nasm
* ld
* objdump
* gcc

Installation de différents package :

```bash
yum install nasm
yum install gcc
```

## Création d'un shellcode

Créer un fichier ".asm" avec le code assembleur.
Pour exemple, le code d'un fichier hello.asm permettant d'afficher "Bonjour la SID" :

```bash
[SECTION .text]

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
        db 'Bonjour la SID'
```

Compiler et créer un créer un exécutable :

```bash
nasm -f elf hello.asm
ld -m elf_i386 -s -o hello hello.o
```

Obtenir le code hexadécimal :

```bash
objdump -d hello|grep '[0-9a-f]:'|grep -v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\t' ' '|sed 's/ $//g'|sed 's/ /\\x/g'|paste -d '' -s |sed 's/^/"/'|sed 's/$/"/g'
```

On obtient le code suivant :

```bash
"\xeb\x19\x31\xc0\x31\xdb\x31\xd2\x31\xc9\xb0\x04\xb3\x01\x59\xb2\x0e\xcd\x80\x31\xc0\xb0\x01\x31\xdb\xcd\x80\xe8\xe2\xff\xff\xff\x42\x6f\x6e\x6a\x6f\x75\x72\x20\x6c\x61\x20\x53\x49\x44"
```

On utilise ce code dans le fichier hello.c (un script c) :

```c
char code[] =
"\xeb\x19\x31\xc0\x31\xdb\x31\xd2\x31\xc9"
"\xb0\x04\xb3\x01\x59\xb2\x0e\xcd\x80\x31"
"\xc0\xb0\x01\x31\xdb\xcd\x80\xe8\xe2\xff"
"\xff\xff\x42\x6f\x6e\x6a\x6f\x75\x72\x20"
"\x6c\x61\x20\x53\x49\x44";

int main(int argc, char **argv)
{
        int (*func)();
        func = (int (*)()) code;
        (int)(*func)();
}
```

On obtient donc un fichier "a.out" que l'on peut exécuter :

```bash
./a.out
```

On obtient le résultat suivant :

```bash
Bonjour la SID#
```