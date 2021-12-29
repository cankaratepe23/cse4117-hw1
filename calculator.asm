.data
        zero: 0
        // push_button_1: 0xd000
        // push_button_2: 0xd001
        // switchboard_1: 0xd002
        // switchboard_2: 0xd003
        // segment_disp: 0xd004
.code
                    push 0              // initialize stack
                    ldi 0 0             // reg0 = 0
                    call poll_setup
poll                ld 6 2              // reg6 = (value from push_button_1)
                    sub 6 1 6
                    jz read_switchboard_1
                    ld 6 3              // reg6 = (value from push_button_2)
                    sub 6 1 6
                    jz read_switchboard_2
                    jmp poll
read_switchboard_1  ldi 6 0xd002        // reg6 = 0xd002
                    ld 6 6              // reg6 = (value from switchboard_1)
                    add 0 0 0           // reg0 = 2 * reg0
                    add 0 0 6           // reg0 = reg0 + reg6
                    ldi 5 0xd004        // reg5 = 0xd004
                    push 0
                    call bcd
                    st 5 0              // (7-segment display) = reg0
                    pop 0
                    jmp wait_pb_1
read_switchboard_2  ldi 6 0xd003        // reg6 = 0xd003
                    ld 6 6              // reg6 = (value from switchboard_2)
                    mov 1 0             // reg1 = reg0
                    mov 2 6             // reg2 = reg6
                    call mult           // reg0 = reg1 * reg2
                    ldi 5 0xd004        // reg5 = 0xd004
                    push 0
                    call bcd
                    st 5 0              // (7-segment display) = reg0
                    pop 0
                    jmp wait_pb_2
wait_pb_1           ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
                    ld 6 2              // reg6 = (value from push_button_1)
                    sub 6 1 6
                    jz wait_pb_1
                    call poll_setup
                    jmp poll
wait_pb_2           ldi 1 1             // reg1 = 1
                    ldi 2 0xd001        // reg2 = 0xd001
                    ld 6 2              // reg6 = (value from push_button_2)
                    sub 6 1 6
                    jz wait_pb_2
                    call poll_setup
                    jmp poll


// poll_setup: reg1, reg2, and reg3 are setup to the appropriate constants for polling
// values of reg1, reg2, and reg3 are NOT preserved
poll_setup          ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
                    ldi 3 0xd001        // reg3 = 0xd001
                    ret


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