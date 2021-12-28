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
                    ldi 1 1             // reg1 = 1
                    ldi 2 0xd000        // reg2 = 0xd000
                    ldi 3 0xd001        // reg3 = 0xd001
poll                ld 6 2              // reg6 = (value from push_button_1)
                    sub 6 1 6
                    jz read_switchboard_1
                    ld 6 3              // reg6 = (value from push_button_2)
                    sub 6 1 6
                    jz read_switchboard_2
                    jmp poll
read_switchboard_1  ldi 6 0xd002        // reg6 = 0xd002
                    ld 6 6              // reg6 = (value from switchboard_1)
                    ldi 5 0xd004        // reg5 = 0xd004
                    st 5 6              // (7-segment display) = reg6
                    jmp poll
read_switchboard_2  ldi 6 0xd003        // reg6 = 0xd003
                    ld 6 6              // reg6 = (value from switchboard_2)
                    ldi 5 0xd004        // reg5 = 0xd004
                    st 5 6              // (7-segment display) = reg6
                    jmp poll
