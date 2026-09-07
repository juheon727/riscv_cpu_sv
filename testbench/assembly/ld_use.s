.globl _start

_start:
    addi x2, x0, 16
    sd x2, 0(x0)
    ld x3, 0(x0)
    add x1, x2, x3