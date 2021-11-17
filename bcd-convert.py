number = 1792


def get_digit(inputnum, bigsub, smallsub):
    global number
    while True:
        if inputnum - bigsub < 0:
            break
        else:
            inputnum = inputnum - bigsub
    digit = 0
    number = number - inputnum
    while inputnum != 0:
        inputnum = inputnum - smallsub
        digit = digit + 1
    print(digit)


get_digit(number, 10, 1)
get_digit(number, 100, 10)
get_digit(number, 1000, 100)
get_digit(number, 10000, 1000)
