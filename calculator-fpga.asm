.data
                zero: 0
                                // keypad: 0xd000
                                // keypad_ready: 0xd001
                                // segment_disp: 0xd002
.code           
                push 0          // initialize stack
start           call poll_and_read
                call write_display
                // check if # or * or A
                jmp start  // continue polling

// Keypad is polled and its value is read into register 0
poll_and_read   push 1
                ldi 1 0xd001    // keypad's ready bit
poll_loop       ld 0 1          // reg0 = ready_bit
                mov 0 0         // to set zero flag
                jz poll_loop    // poll until ready bit is 1
                ldi 1 0xd000    // keypad's address
                ld 0 1          // reg0 = (keypad value)
                pop 1
                ret

// Register 0 is written to 7 segment display
write_display   push 1
                ldi 1 0xd002    // 7 segment address
                st 1 0          // write value to 7 segment
                pop 1
                ret