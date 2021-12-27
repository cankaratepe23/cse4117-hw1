.data
                zero: 0
                one: 1
                two: 2
.code
                push 0
                ldi 0 zero
                ld 0 0
                ldi 1 one
                ld 1 1
                call push_to_stack
                ldi 1 two
                ld 1 1
                call push_to_stack
                pop 2
                pop 2
                jmp exit
exit            jmp exit
push_to_stack   push 1
                ret