.data
        zero: 0
        terms: 7
        negone: 0xffff
        negtwo: 0xfffe
.code
        ldi 1 terms
        ld 1 1
        ldi 0 zero
        ld 0 0
        ldi 6 negone
        ld 6 6
        ldi 7 negtwo
        ld 7 7
fori    xor 5 1 6
        jz exit
        ldi 2 zero
        ld 2 2
        mov 3 1
forj    add 2 2 1
        dec 3
        jz forico
        jmp forj
forico  add 0 0 2
        add 1 1 7
        jmp fori
exit    jmp exit

