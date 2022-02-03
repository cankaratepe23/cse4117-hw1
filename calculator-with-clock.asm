.data
        zero: 0
        // push_button_1: 0xd000
        // switchboard_1: 0xd001
        // switchboard_2: 0xd002
        // segment_disp: 0xd003
        // timer_time_val: 0xd004
        // timer_disp: 0xd005
        // PIC_mask: 0xd006
        // Interrupt Table start: 0xe000
.code
                    push 0              // initialize stack
                    ldi 0 0xe000        // put first ISR into
                    ldi 1 isr1
                    st 0 1              // interrupt table
                    sti                 // and then enable the interrupts
                    ldi 0 0             // reg0 = 0
                    call poll_setup     // reg1 = 1; reg2 = 0xd000
poll                ld 5 2              // reg5 = (value from push_button_1)
                    sub 5 1 5           // reg5 = reg5 - 1;
                    jz add_switchboards // jump if reg5 was 1
                    jmp poll            // continue polling if not
add_switchboards    ldi 5 0xd001        // reg5 = 0xd001
                    ld 5 5              // reg5 = (value from switchboard_1)
                    ldi 0 0xd002        // reg0 = 0xd001
                    ld 0 0              // reg0 = (value from switchboard_2)
                    add 0 0 5           // reg0 = reg0 + reg5
                    ldi 5 0xd003        // reg5 = 0xd003
                    push 0
                    call bcd
                    st 5 0              // (7-segment display) = reg0
                    pop 0
wait_pb_1           ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
                    ld 5 2              // reg5 = (value from push_button_1)
                    sub 5 1 5
                    jz wait_pb_1        // continue waiting if reg5 was 1
                    call poll_setup
                    jmp poll            // start polling if not


isr1    ldi 0 0xd006
        ldi 1 0x0001
        st 0 1
        ldi 0 0xd004
        ld 0 0
        sti
        call bcd
        ldi 1 0xd005
        st 1 0
        ldi 0 0xd006
        ldi 1 0x0000
        st 0 1
        iret

// poll_setup: reg1 and reg2 are setup to the appropriate constants for polling
// values of reg1 and reg2 are NOT preserved
poll_setup          ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
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

                    ldi 0 0xffff    // reg0 = -1
                    ldi 5 1         // reg5 = 1
                    ldi 4 0x8000    // reg4 = 0x8000 (integer with only MSB = 1)
div_loop            mov 3 1         // reg3 = reg1
                    add 0 0 5       // reg0++
                    sub 1 1 2       // reg1 = reg1 - reg2
                    push 5
                    and 5 1 4       // ZF is set if 0 is positive. reg5 is a discard register
                    pop 5
                    jz div_loop

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
                    
                    mov 1 0
                    ldi 2 1000
                    call div        // reg0 = reg0 / 1000 && reg3 = reg0 % 1000

                    ldi 1 12
                    call shl
                    mov 5 0

                    mov 1 3
                    ldi 2 100
                    call div        // reg0 = reg3 / 100 && reg3 = reg3 % 100

                    ldi 1 8
                    call shl        // 8-bit shift the result from prev. operation)
                    or 5 5 0        // store the bit-shifted result of division in reg6

                    mov 1 3
                    ldi 2 10
                    call div        // reg0 = reg3 / 10 && reg3 = reg3 % 10

                    ldi 1 4
                    call shl        // 4-bit shift the result from prev. operation)
                    or 5 5 0        // store the bit-shifted result of division in reg6

                    or 5 5 3        // store the final nibble in reg6

                    mov 0 5         // return value in reg5
                    pop 5
                    pop 4
                    pop 3
                    pop 2
                    pop 1
                    ret
