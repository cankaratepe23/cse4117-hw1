.data
                zero: 0
                // * = 0x000E
                // # = 0x000F
.code
                push 0              // initialize stack
start           call poll_and_read  // read a character

                // reg0 is used for function return values
                // reg5 is the current entered operand

                mov 4 0             // put the new character into another register for safe-keeping
                mov 1 0
                ldi 2 0x000e
                sub 0 1 2           // if entered key is 0xe
                jz mul_op           // go to multiplication
                ldi 2 0x000f
                sub 0 1 2           // if entered key is 0xf
                jz sum_op           // go to addition
                //// default case, a new digit is entered:
                mov 1 5             // prepare to mult the previous number by 10
                ldi 2 10
                call mult           // reg0 = reg5 * 10
                add 0 0 4           // add the new number to the multiplied old number
                mov 5 0             // the current number resides in reg0 and reg5
                call write_display
                jmp start           // continue polling
sum_op          push 0              // placeholder
mul_op          push 0              // placeholder         

// mult: reg0 = reg1 * reg2
// value of reg0 is NOT preserved
mult                push 1
                    push 2
                    push 3
                    ldi 3 1
                    ldi 0 0
mult_loop           add 0 0 1           // sum = sum + reg1
                    sub 2 2 3           // reg2--
                    jz mult_return
                    jmp mult_loop
mult_return         pop 3
                    pop 2
                    pop 1
                    ret

// Keypad is polled and its value is read into register 0
poll_and_read   push 1
                ldi 1 0x00E0    // keypad's ready bit
poll_loop       ld 0 1          // reg0 = ready_bit
                mov 0 0         // to set zero flag
                jz poll_loop    // poll until ready bit is 1
                ldi 1 0x00DF    // keypad's address
                ld 0 1          // reg0 = (keypad value)
                pop 1
                ret

// shl: reg0 = reg0 << reg1
// value of reg0 is NOT preserved
shl                 push 1
                    push 2
                    
                    ldi 2 1
shl_loop            add 0 0 0       // reg0 = reg0 * 2
                    sub 1 1 2       // reg1--
                    jz shl_return
                    jmp shl_loop
shl_return          pop 2
                    pop 1
                    ret

// div: reg0 = reg1 / reg2 (integer division) & reg3 = remainder
// values of reg0 and reg3 are NOT preserved
div                 push 1
                    push 2
                    push 4
                    push 5
                    push 6

                    ldi 0 0xffff    // reg0 = -1
                    ldi 6 1         // reg6 = 1
                    ldi 4 0x8000    // reg4 = 0x8000 (integer with only MSB = 1)
div_loop            mov 3 1         // reg3 = reg1
                    add 0 0 6       // reg0++
                    sub 1 1 2       // reg1 = reg1 - reg2
                    and 5 1 4       // ZF is set if 0 is positive. reg5 is a discard register
                    jz div_loop

                    pop 6
                    pop 5
                    pop 4
                    pop 2
                    pop 1
                    ret

// bcd: converts integer value given in reg0, inplace, to its BCD value.
bcd                 push 1
                    push 2
                    push 3
                    push 4
                    push 5
                    push 6
                    
                    mov 1 0
                    ldi 2 1000
                    call div        // reg0 = reg0 / 1000 && reg3 = reg0 % 1000

                    ldi 1 12
                    call shl
                    mov 6 0

                    mov 1 3
                    ldi 2 100
                    call div        // reg0 = reg3 / 100 && reg3 = reg3 % 100

                    ldi 1 8
                    call shl        // 8-bit shift the remainder from prev. operation)
                    or 6 6 0        // store the bit-shifted result of division in reg6

                    mov 1 3
                    ldi 2 10
                    call div        // reg0 = reg3 / 10 && reg3 = reg3 % 10

                    ldi 1 4
                    call shl        // 4-bit shift the remainder from prev. operation)
                    or 6 6 0        // store the bit-shifted result of division in reg6

                    or 6 6 3        // store the final nibble in reg6

                    mov 0 6         // return value in reg6
                    pop 6
                    pop 5
                    pop 4
                    pop 3
                    pop 2
                    pop 1
                    ret

// Register 0 is written to 7 segment display
write_display   push 1
                ldi 1 0x00E1    // 7 segment address
                call bcd
                st 1 0          // write value to 7 segment
                pop 1
                ret