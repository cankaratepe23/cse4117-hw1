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
                ldi 1 0x005d    // keypad's ready bit
poll_loop       ld 0 1          // reg0 = ready_bit
                mov 0 0         // to set zero flag
                jz poll_loop    // poll until ready bit is 1
                ldi 1 0x005c    // keypad's address
                ld 0 1          // reg0 = (keypad value)
                pop 1
                ret

// Register 0 is written to 7 segment display
write_display   push 1
                ldi 1 0x005e    // 7 segment address
                st 1 0          // write value to 7 segment
                pop 1
                ret