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
                    st 5 0              // (7-segment display) = reg0
                    jmp wait_pb_1
read_switchboard_2  ldi 6 0xd003        // reg6 = 0xd003
                    ld 6 6              // reg6 = (value from switchboard_2)
                    mov 1 0             // reg1 = reg0
                    mov 2 6             // reg2 = reg6
                    call mult           // reg0 = reg1 * reg2
                    ldi 5 0xd004        // reg5 = 0xd004
                    st 5 0              // (7-segment display) = reg0
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
poll_setup          ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
                    ldi 3 0xd001        // reg3 = 0xd001
                    ret


// mult: reg0 = reg1 * reg2
// values of reg1, reg2 and reg3 are preserved
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
